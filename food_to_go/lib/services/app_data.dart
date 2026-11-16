import 'package:flutter/foundation.dart';

import '../models/food_item.dart';
import '../models/food_stall.dart';
import 'cart_service.dart';

class AppData extends ChangeNotifier {
  AppData() {
    cart.addListener(notifyListeners);
  }

  final CartService cart = CartService();

  final List<FoodStall> stalls = [
    FoodStall(
      id: 'waffle_time',
      name: 'Waffle Time',
      description: 'Freshly made waffles and sweet treats.',
      imageUrl:
          'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=800',
      menu: [
        FoodItem(
          id: 'waffle_1',
          name: 'Classic Belgian Waffle',
          description: 'A golden Belgian waffle with a soft center.',
          imageUrl:
              'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=800',
          soloPrice: 65,
          mealPrice: 95,
        ),
        FoodItem(
          id: 'waffle_2',
          name: 'Chocolate Waffle',
          description: 'A waffle topped with rich chocolate sauce.',
          imageUrl:
              'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=800',
          soloPrice: 75,
          mealPrice: 105,
        ),
        FoodItem(
          id: 'waffle_3',
          name: 'Strawberry Waffle',
          description: 'A sweet waffle with strawberry toppings.',
          imageUrl:
              'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=800',
          soloPrice: 80,
          mealPrice: 110,
        ),
      ],
    ),
    FoodStall(
      id: 'burpngo',
      name: "Burp'nGo",
      description: 'Quick bites and satisfying meals.',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
      menu: [
        FoodItem(
          id: 'burger_1',
          name: 'Classic Burger',
          description: 'A beef patty with fresh lettuce and sauce.',
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
          soloPrice: 75,
          mealPrice: 115,
        ),
        FoodItem(
          id: 'burger_2',
          name: 'Cheese Burger',
          description: 'A classic burger topped with melted cheese.',
          imageUrl:
              'https://images.unsplash.com/photo-1553979459-d2229ba7433a?w=800',
          soloPrice: 85,
          mealPrice: 125,
        ),
      ],
    ),
    FoodStall(
      id: 'coffee_shop',
      name: 'Coffee Shop',
      description: 'Coffee, refreshments, and light snacks.',
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800',
      menu: [
        FoodItem(
          id: 'coffee_1',
          name: 'Iced Coffee',
          description: 'Chilled coffee served over ice.',
          imageUrl:
              'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=800',
          soloPrice: 65,
          mealPrice: 95,
        ),
        FoodItem(
          id: 'coffee_2',
          name: 'Caramel Latte',
          description: 'A creamy latte with caramel flavor.',
          imageUrl:
              'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800',
          soloPrice: 85,
          mealPrice: 115,
        ),
      ],
    ),
  ];

  final Set<String> _favoriteIds = {};
  final Map<String, int> _stallLikes = {};

  List<FoodStall> get availableStalls => List.unmodifiable(stalls);

  FoodStall? getStall(String id) {
    for (final stall in stalls) {
      if (stall.id == id) return stall;
    }
    return null;
  }

  FoodItem? getFood(String foodId) {
    for (final stall in stalls) {
      for (final food in stall.menu) {
        if (food.id == foodId) return food;
      }
    }
    return null;
  }

  bool isFavorite(String foodId) => _favoriteIds.contains(foodId);

  List<FoodItem> get favorites {
    return _favoriteIds
        .map(getFood)
        .whereType<FoodItem>()
        .toList();
  }

  void toggleFavorite(String foodId) {
    if (_favoriteIds.contains(foodId)) {
      _favoriteIds.remove(foodId);
    } else {
      _favoriteIds.add(foodId);
    }
    notifyListeners();
  }

  int likesFor(String stallId) => _stallLikes[stallId] ?? 0;

  void likeStall(String stallId) {
    _stallLikes[stallId] = likesFor(stallId) + 1;
    notifyListeners();
  }

  void addFood(String stallId, FoodItem food) {
    final stall = getStall(stallId);
    if (stall == null) return;

    stall.menu.add(food);
    notifyListeners();
  }

  void updateFood(String stallId, FoodItem updatedFood) {
    final stall = getStall(stallId);
    if (stall == null) return;

    final index = stall.menu.indexWhere(
      (item) => item.id == updatedFood.id,
    );

    if (index == -1) return;

    stall.menu[index] = updatedFood;
    notifyListeners();
  }

  void deleteFood(String stallId, String foodId) {
    final stall = getStall(stallId);
    if (stall == null) return;

    stall.menu.removeWhere((item) => item.id == foodId);
    _favoriteIds.remove(foodId);
    notifyListeners();
  }

  void toggleAvailability(String stallId, String foodId) {
    final food = getFood(foodId);
    if (food == null) return;

    food.isAvailable = !food.isAvailable;
    notifyListeners();
  }

  @override
  void dispose() {
    cart.removeListener(notifyListeners);
    cart.dispose();
    super.dispose();
  }
}