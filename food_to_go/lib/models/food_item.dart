
class FoodItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double soloPrice;
  final double mealPrice;

  // These two properties can change while the app is running.
  bool isAvailable;
  int orderCount;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.soloPrice,
    required this.mealPrice,
    this.isAvailable = true,
    this.orderCount = 0,
  });
}
