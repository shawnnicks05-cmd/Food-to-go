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
      menu: const [
        FoodItem(
          id: 'waffle_1',
          name: 'Classic Belgian Waffle',
          description:
              'A golden Belgian waffle with a soft center and crispy exterior.',
          imageUrl:
              'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=800',
          soloPrice: 65,
          mealPrice: 95,
        ),
        FoodItem(
          id: 'waffle_2',
          name: 'Chocolate Waffle',
          description:
              'A delicious waffle topped with rich chocolate sauce.',
          imageUrl:
              'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=800',
          soloPrice: 75,
          mealPrice: 105,
        ),
        FoodItem(
          id: 'waffle_3',
          name: 'Strawberry Waffle',
          description:
              'A sweet waffle served with strawberry toppings.',
          imageUrl:
              'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=800',
          soloPrice: 80,
          mealPrice: 110,
        ),
        FoodItem(
          id: 'waffle_4',
          name: 'Blueberry Waffle',
          description:
              'A fluffy waffle with sweet blueberry toppings.',
          imageUrl:
              'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
          soloPrice: 85,
          mealPrice: 115,
        ),
      ],
    ),

    FoodStall(
      id: 'burpngo',
      name: "Burp'nGo",
      description: 'Quick bites and satisfying meals.',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
      menu: const [
        FoodItem(
          id: 'burger_1',
          name: 'Classic Burger',
          description: 'A juicy beef patty with fresh lettuce and sauce.',
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
          soloPrice: 75,
          mealPrice: 115,
        ),
        FoodItem(
          id: 'burger_2',
          name: 'Cheese Burger',
          description: 'Classic burger topped with melted cheese.',
          imageUrl:
              'https://images.unsplash.com/photo-1553979459-d2229ba7433a?w=800',
          soloPrice: 85,
          mealPrice: 125,
        ),
      ],
    ),

    FoodStall(
      id: 'coffee_shop',
      name: 'Coffee Shop',
      description: 'Coffee, refreshments, and light snacks.',
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800',
      menu: const [
        FoodItem(
          id: 'coffee_1',
          name: 'Iced Coffee',
          description: 'Chilled coffee served over ice.',
          imageUrl:
              'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=800',
          soloPrice: 65,
          mealPrice: 95,
        ),
        FoodItem(
          id: 'coffee_2',
          name: 'Caramel Latte',
          description: 'A creamy latte with caramel flavor.',
          imageUrl:
              'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800',
          soloPrice: 85,
          mealPrice: 115,
        ),
      ],
    ),
  ];

  @override
  List<FoodStall> getStalls() {
    return List.unmodifiable(_stalls);
  }

  @override
  FoodStall? getStallById(String id) {
    try {
      return _stalls.firstWhere((stall) => stall.id == id);
    } catch (_) {
      return null;
    }
  }
}