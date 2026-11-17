import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/food_item.dart';
import '../models/food_stall.dart';
import 'cart_service.dart';

class AppData extends ChangeNotifier {
  static const _foodImagesBucket = 'food-images';

  AppData({SupabaseClient? client}) : this._(client, []);

  AppData.withStalls(List<FoodStall> initialStalls)
    : this._(null, initialStalls);

  AppData._(this._client, this._stalls) {
    cart.addListener(notifyListeners);
  }

  final SupabaseClient? _client;
  final CartService cart = CartService();
  final List<FoodStall> _stalls;
  final Set<String> _favoriteIds = {};
  final Set<String> _likedStalls = {};

  String? _userId;
  String? _loadError;
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<FoodStall> get stalls => List.unmodifiable(_stalls);
  List<FoodStall> get availableStalls => stalls;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  static const _loadTimeout = Duration(seconds: 20);

  FoodStall? getStall(String id) {
    for (final stall in _stalls) {
      if (stall.id == id) return stall;
    }
    return null;
  }

  FoodItem? getFood(String foodId) {
    for (final stall in _stalls) {
      for (final food in stall.menu) {
        if (food.id == foodId) return food;
      }
    }
    return null;
  }

  bool isFavorite(String foodId) => _favoriteIds.contains(foodId);

  List<FoodItem> get favorites =>
      _favoriteIds.map(getFood).whereType<FoodItem>().toList(growable: false);

  bool hasLiked(String stallId) => _likedStalls.contains(stallId);

  int likesFor(String stallId) => getStall(stallId)?.likeCount ?? 0;

  Future<void> setUser(String? userId) async {
    if (_client == null) return;
    if (_userId == userId && (userId == null || _hasLoaded || _isLoading)) {
      return;
    }

    _userId = userId;
    _favoriteIds.clear();
    _likedStalls.clear();
    _loadError = null;

    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _client.from('food_stalls').select().order('name'),
        _client.from('food_items').select().order('name'),
        _client.from('favorites').select('food_item_id').eq('user_id', userId),
        _client.from('stall_likes').select('stall_id').eq('user_id', userId),
      ]).timeout(_loadTimeout);

      final stallRows = results[0];
      final foodRows = results[1];
      final favoriteRows = results[2];
      final likeRows = results[3];

      if (_userId != userId) return;

      final menuByStall = <String, List<FoodItem>>{};
      for (final row in foodRows) {
        final item = FoodItem.fromMap(row);
        menuByStall.putIfAbsent(row['stall_id'] as String, () => []).add(item);
      }

      _stalls
        ..clear()
        ..addAll(
          stallRows.map(
            (row) => FoodStall.fromMap(row, menu: menuByStall[row['id']] ?? []),
          ),
        );
      _favoriteIds.addAll(
        favoriteRows.map((row) => row['food_item_id'] as String),
      );
      _likedStalls.addAll(likeRows.map((row) => row['stall_id'] as String));
      _hasLoaded = true;
    } on TimeoutException {
      if (_userId == userId) {
        _loadError =
            'Supabase did not respond within 20 seconds. Check your internet '
            'connection, Supabase project status, and database policies, then retry.';
      }
    } on PostgrestException catch (error) {
      if (_userId == userId && error.code == 'PGRST205') {
        _loadError =
            'A required Supabase table is missing from the API schema. Run '
            'food_to_go/supabase/schema.sql in the Supabase SQL Editor. If the '
            'table already exists, run: NOTIFY pgrst, \'reload schema\';';
      } else if (_userId == userId) {
        final message = error.message.toLowerCase();
        _loadError =
            message.contains('permission denied') &&
                message.contains('favorites')
            ? 'Supabase denied access to your favorites table. Run '
                  'GRANT SELECT, INSERT, DELETE ON public.favorites TO authenticated; '
                  'in the Supabase SQL Editor, then tap Try again.'
            : 'Supabase data request failed: ${error.message}';
      }
    } catch (error) {
      if (_userId == userId) {
        _loadError = 'Supabase data request failed: $error';
      }
    } finally {
      if (_userId == userId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryLoad() async {
    final userId = _userId;
    if (userId != null) {
      _hasLoaded = false;
      await setUser(userId);
    }
  }

  Future<List<PendingStallAccount>> loadPendingStallAccounts() async {
    final response = await _requireClient().rpc(
      'list_pending_food_stall_accounts',
    );
    if (response is! List) {
      throw const FormatException(
        'Supabase returned an invalid pending-account list.',
      );
    }

    return response.map((row) {
      if (row is! Map || row['user_id'] is! String || row['email'] is! String) {
        throw const FormatException(
          'Supabase returned an incomplete pending account.',
        );
      }
      return PendingStallAccount(
        userId: row['user_id'] as String,
        email: row['email'] as String,
      );
    }).toList();
  }

  Future<void> approveFoodStallAccount({
    required String userId,
    required String stallId,
  }) async {
    await _requireClient().rpc(
      'approve_food_stall_account',
      params: {'p_user_id': userId, 'p_stall_id': stallId},
    );
  }

  Future<void> toggleFavorite(String foodId) async {
    final client = _requireClient();
    final userId = _requireUser();

    if (_favoriteIds.contains(foodId)) {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('food_item_id', foodId);
      _favoriteIds.remove(foodId);
    } else {
      await client.from('favorites').insert({
        'user_id': userId,
        'food_item_id': foodId,
      });
      _favoriteIds.add(foodId);
    }
    notifyListeners();
  }

  Future<void> likeStall(String stallId) async {
    final client = _requireClient();
    final userId = _requireUser();
    final stall = getStall(stallId);
    if (stall == null) throw StateError('Food stall "$stallId" was not found.');
    if (_likedStalls.contains(stallId)) return;

    await client.from('stall_likes').insert({
      'user_id': userId,
      'stall_id': stallId,
    });

    _likedStalls.add(stallId);
    stall.likeCount++;
    notifyListeners();
  }

  Future<void> addFood(String stallId, FoodItem food) async {
    final client = _requireClient();
    final stall = getStall(stallId);
    if (stall == null) throw StateError('Food stall "$stallId" was not found.');

    final row = await client
        .from('food_items')
        .insert(food.toInsertMap(stallId))
        .select()
        .single();
    stall.menu.add(FoodItem.fromMap(row));
    notifyListeners();
  }

  Future<String> uploadFoodImage({
    required String stallId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final client = _requireClient();
    _requireUser();

    if (getStall(stallId) == null) {
      throw StateError('Food stall "$stallId" was not found.');
    }

    final extension = fileName.split('.').last.toLowerCase();
    const contentTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
    };
    final contentType = contentTypes[extension];
    if (contentType == null) {
      throw const FormatException('Choose a JPG, PNG, WebP, or GIF image.');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException(
        'Image files must be between 1 byte and 5 MB.',
      );
    }

    final path = '$stallId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await client.storage
        .from(_foodImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return client.storage.from(_foodImagesBucket).getPublicUrl(path);
  }

  Future<void> updateFood(String stallId, FoodItem updatedFood) async {
    final client = _requireClient();
    final stall = getStall(stallId);
    if (stall == null) throw StateError('Food stall "$stallId" was not found.');

    final row = await client
        .from('food_items')
        .update(updatedFood.toUpdateMap())
        .eq('id', updatedFood.id)
        .eq('stall_id', stallId)
        .select()
        .maybeSingle();
    if (row == null) {
      throw StateError('The menu item could not be updated.');
    }

    final index = stall.menu.indexWhere((item) => item.id == updatedFood.id);
    if (index == -1) {
      throw StateError('Menu item "${updatedFood.id}" was not found.');
    }
    stall.menu[index] = FoodItem.fromMap(row);
    notifyListeners();
  }

  Future<void> deleteFood(String stallId, String foodId) async {
    final client = _requireClient();
    final stall = getStall(stallId);
    if (stall == null) throw StateError('Food stall "$stallId" was not found.');

    await client
        .from('food_items')
        .delete()
        .eq('id', foodId)
        .eq('stall_id', stallId);
    stall.menu.removeWhere((item) => item.id == foodId);
    _favoriteIds.remove(foodId);
    notifyListeners();
  }

  Future<void> toggleAvailability(String stallId, String foodId) async {
    final client = _requireClient();
    final stall = getStall(stallId);
    final food = getFood(foodId);
    if (stall == null || food == null) {
      throw StateError('The menu item could not be found.');
    }

    final row = await client
        .from('food_items')
        .update({'is_available': !food.isAvailable})
        .eq('id', foodId)
        .eq('stall_id', stallId)
        .select()
        .maybeSingle();
    if (row == null) {
      throw StateError('The menu item availability could not be updated.');
    }

    final index = stall.menu.indexWhere((item) => item.id == foodId);
    stall.menu[index] = FoodItem.fromMap(row);
    notifyListeners();
  }

  Future<PlacedOrder> placeOrder({
    required List<CartItem> items,
    required String paymentMethod,
  }) async {
    final client = _requireClient();
    _requireUser();

    final response = await client.rpc(
      'place_food_order',
      params: {
        'p_items': items
            .map(
              (item) => {
                'food_id': item.food.id,
                'purchase_type': item.purchaseType.name,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'p_payment_method': paymentMethod,
      },
    );

    if (response is! Map) {
      throw const FormatException('Supabase returned an invalid order result.');
    }
    final total = response['total'];
    final itemCount = response['item_count'];
    final orderId = response['order_id'];
    if (total is! num || itemCount is! num || orderId is! String) {
      throw const FormatException('Supabase returned an incomplete order.');
    }

    for (final item in items) {
      final food = getFood(item.food.id);
      if (food != null) food.orderCount += item.quantity;
    }
    notifyListeners();

    return PlacedOrder(
      id: orderId,
      total: total.toDouble(),
      itemCount: itemCount.toInt(),
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for this application.');
    }
    return client;
  }

  String _requireUser() {
    final userId = _userId;
    if (userId == null) {
      throw StateError('Sign in before saving account data.');
    }
    return userId;
  }

  @override
  void dispose() {
    cart.removeListener(notifyListeners);
    cart.dispose();
    super.dispose();
  }
}

class PendingStallAccount {
  const PendingStallAccount({required this.userId, required this.email});

  final String userId;
  final String email;
}

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.total,
    required this.itemCount,
  });

  final String id;
  final double total;
  final int itemCount;
}
