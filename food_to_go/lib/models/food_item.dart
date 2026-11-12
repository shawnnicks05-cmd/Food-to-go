class FoodItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double soloPrice;
  final double mealPrice;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.soloPrice,
    required this.mealPrice,
  });
}