import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/food_stall.dart';
import '../services/app_data.dart';
import '../widgets/food_image.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final AppData appData;

  const FavoritesScreen({super.key, required this.appData});

  FoodStall? _findStall(FoodItem food) {
    for (final stall in appData.stalls) {
      if (stall.menu.any((item) => item.id == food.id)) {
        return stall;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (context, child) {
        final favorites = appData.favorites;

        return Scaffold(
          appBar: AppBar(title: const Text('My Favorites')),
          body: favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No favorites yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('Your favorite food items will appear here.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final food = favorites[index];
                    final stall = _findStall(food);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: FoodImage(
                          imageUrl: food.imageUrl,
                          width: 75,
                          height: 75,
                        ),
                        title: Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'From ₱${food.soloPrice.toStringAsFixed(2)}',
                        ),
                        onTap: stall == null
                            ? null
                            : () {
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
                        trailing: IconButton(
                          tooltip: 'Remove from favorites',
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            try {
                              await appData.toggleFavorite(food.id);
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Unable to update favorite: $error',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
