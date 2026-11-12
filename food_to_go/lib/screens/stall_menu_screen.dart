import 'package:flutter/material.dart';

import '../models/food_stall.dart';
import '../models/food_item.dart';
import '../repositories/stall_repository.dart';
import '../services/cart_service.dart';
import '../widgets/food_image.dart';
import 'product_detail_screen.dart';

class StallMenuScreen extends StatelessWidget {
  final String stallId;
  final StallRepository repository;
  final CartService cart;

  const StallMenuScreen({
    super.key,
    required this.stallId,
    required this.repository,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final FoodStall? stall = repository.getStallById(stallId);

    if (stall == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Food Stall')),
        body: const Center(
          child: Text('Food stall not found.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(stall.name),
        actions: [
          AnimatedBuilder(
            animation: cart,
            builder: (context, child) {
              return IconButton(
                tooltip: 'Shopping cart',
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: Badge(
                  label: Text('${cart.totalItems}'),
                  isLabelVisible: cart.totalItems > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: FoodImage(
                imageUrl: stall.imageUrl,
                height: 170,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              stall.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              stall.description,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Available Menu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...stall.menu.map(
              (food) => _FoodMenuCard(
                food: food,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        food: food,
                        stall: stall,
                        cart: cart,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodMenuCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;

  const _FoodMenuCard({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FoodImage(
                imageUrl: food.imageUrl,
                height: 105,
                width: 105,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'From ₱${food.soloPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}