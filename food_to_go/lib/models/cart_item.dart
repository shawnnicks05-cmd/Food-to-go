import 'food_item.dart';

enum PurchaseType {
  solo,
  meal,
}

class CartItem {
  final FoodItem food;
  final PurchaseType purchaseType;
  final int quantity;

  const CartItem({
    required this.food,
    required this.purchaseType,
    required this.quantity,
  });

  double get unitPrice {
    return purchaseType == PurchaseType.meal
        ? food.mealPrice
        : food.soloPrice;
  }

  double get subtotal => unitPrice * quantity;

  String get purchaseLabel {
    return purchaseType == PurchaseType.meal
        ? 'Meal'
        : 'Solo';
  }

  CartItem copyWith({
    int? quantity,
    PurchaseType? purchaseType,
  }) {
    return CartItem(
      food: food,
      purchaseType: purchaseType ?? this.purchaseType,
      quantity: quantity ?? this.quantity,
    );
  }
}