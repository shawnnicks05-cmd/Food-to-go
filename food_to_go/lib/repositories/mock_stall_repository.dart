import '../models/food_item.dart';
import '../models/food_stall.dart';
import 'stall_repository.dart';

class MockStallRepository implements StallRepository {
  final List<FoodStall> _stalls = [
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
      ],
    ),
  ];

  @override
  List<FoodStall> getStalls() => List.unmodifiable(_stalls);

  @override
  FoodStall? getStallById(String id) {
    for (final stall in _stalls) {
      if (stall.id == id) return stall;
    }
    return null;
  }
}