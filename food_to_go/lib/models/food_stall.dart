import 'food_item.dart';

class FoodStall {
  final String id;
  String name;
  String description;
  String imageUrl;
  int likeCount;
  final List<FoodItem> menu;

  FoodStall({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.likeCount = 0,
    required this.menu,
  });

  factory FoodStall.fromMap(
    Map<String, dynamic> row, {
    required List<FoodItem> menu,
  }) {
    return FoodStall(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      imageUrl: row['image_url'] as String? ?? '',
      likeCount: row['like_count'] as int? ?? 0,
      menu: menu,
    );
  }
}
