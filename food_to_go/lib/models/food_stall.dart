import 'food_item.dart';

class FoodStall {
  final String id;
  String name;
  String description;
  String imageUrl;
  final List<FoodItem> menu;

  FoodStall({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.menu,
  });
}