import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems {
    return _items.fold(
      0,
      (total, item) => total + item.quantity,
    );
  }

  double get totalPrice {
    return _items.fold(
      0,
      (total, item) => total + item.subtotal,
    );
  }

  void addItem(
    FoodItem food,
    PurchaseType type,
    int quantity,
  ) {
    if (quantity < 1) return;

    final index = _items.indexWhere(
      (item) =>
          item.food.id == food.id &&
          item.purchaseType == type,
    );

    if (index != -1) {
      final existing = _items[index];

      _items[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      _items.add(
        CartItem(
          food: food,
          purchaseType: type,
          quantity: quantity,
        ),
      );
    }

    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= _items.length) return;

    if (quantity <= 0) {
      removeItem(index);
      return;
    }

    _items[index] = _items[index].copyWith(
      quantity: quantity,
    );

    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;

    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}