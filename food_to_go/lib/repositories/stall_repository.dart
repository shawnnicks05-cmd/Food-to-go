import '../models/food_stall.dart';

abstract class StallRepository {
  List<FoodStall> getStalls();

  FoodStall? getStallById(String id);
}