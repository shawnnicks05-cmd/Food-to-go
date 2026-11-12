import 'food_item.dart';

class FoodStall {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<FoodItem> menu;

  const FoodStall({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.menu,
  });
}