import 'package:flutter/material.dart';

import '../models/food_stall.dart';
import '../services/app_data.dart';
import '../widgets/food_image.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class StallMenuScreen extends StatelessWidget {
  const StallMenuScreen({
    super.key,
    required this.stallId,
    required this.appData,
  });

  final String stallId;
  final AppData appData;

  Future<void> _likeStall(BuildContext context, FoodStall stall) async {
    try {
      await appData.likeStall(stall.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to like this stall: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FoodStall? stall = appData.getStall(stallId);

    if (stall == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Food Stall')),
        body: const Center(child: Text('Food stall not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(stall.name),
        actions: [
          AnimatedBuilder(
            animation: appData,
            builder: (context, _) {
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(appData: appData),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: appData.cart.totalItems > 0,
                  label: Text('${appData.cart.totalItems}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, _) {
          final availableItems = stall.menu
              .where((food) => food.isAvailable)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FoodImage(imageUrl: stall.imageUrl, height: 170),
              const SizedBox(height: 16),
              Text(
                stall.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(stall.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('${appData.likesFor(stall.id)} likes'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: appData.hasLiked(stall.id)
                        ? null
                        : () => _likeStall(context, stall),
                    icon: Icon(
                      appData.hasLiked(stall.id)
                          ? Icons.thumb_up
                          : Icons.thumb_up_alt_outlined,
                    ),
                    label: Text(appData.hasLiked(stall.id) ? 'Liked' : 'Like'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Available Menu',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (availableItems.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No menu items are currently available.'),
                  ),
                ),
              ...availableItems.map(
                (food) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            food: food,
                            stall: stall,
                            appData: appData,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          FoodImage(
                            imageUrl: food.imageUrl,
                            height: 95,
                            width: 95,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  food.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
