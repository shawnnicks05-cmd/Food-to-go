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

  factory FoodItem.fromMap(Map<String, dynamic> row) {
    return FoodItem(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      imageUrl: row['image_url'] as String? ?? '',
      soloPrice: (row['solo_price'] as num).toDouble(),
      mealPrice: (row['meal_price'] as num).toDouble(),
      isAvailable: row['is_available'] as bool? ?? true,
      orderCount: row['order_count'] as int? ?? 0,
    );
  }

  Map<String, Object> toInsertMap(String stallId) => {
    'stall_id': stallId,
    'name': name,
    'description': description,
    'image_url': imageUrl,
    'solo_price': soloPrice,
    'meal_price': mealPrice,
    'is_available': isAvailable,
  };

  Map<String, Object> toUpdateMap() => {
    'name': name,
    'description': description,
    'image_url': imageUrl,
    'solo_price': soloPrice,
    'meal_price': mealPrice,
    'is_available': isAvailable,
  };
}
