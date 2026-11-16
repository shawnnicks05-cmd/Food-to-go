import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/food_item.dart';
import '../models/food_stall.dart';
import '../services/app_data.dart';
import '../widgets/food_image.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.food,
    required this.stall,
    required this.appData,
  });

  final FoodItem food;
  final FoodStall stall;
  final AppData appData;

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  PurchaseType _selectedType = PurchaseType.solo;
  int _quantity = 1;

  double get _price => _selectedType == PurchaseType.meal
      ? widget.food.mealPrice
      : widget.food.soloPrice;

  void _addToCart() {
    if (!widget.food.isAvailable) return;

    widget.appData.cart.addItem(
      widget.food,
      _selectedType,
      _quantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.food.name} added to cart.'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CartScreen(appData: widget.appData),
              ),
            );
          },
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Order'),
        actions: [
          AnimatedBuilder(
            animation: widget.appData,
            builder: (context, _) {
              final favorite = widget.appData.isFavorite(food.id);

              return IconButton(
                tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                onPressed: () => widget.appData.toggleFavorite(food.id),
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite ? Colors.red : null,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FoodImage(
            imageUrl: food.imageUrl,
            height: 230,
          ),
          const SizedBox(height: 18),
          Text(
            food.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(food.description),
          const SizedBox(height: 24),
          const Text(
            'Choose your order',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _PurchaseOption(
            title: 'Solo',
            description: 'Food item only',
            price: food.soloPrice,
            selected: _selectedType == PurchaseType.solo,
            onTap: () => setState(
              () => _selectedType = PurchaseType.solo,
            ),
          ),
          const SizedBox(height: 10),
          _PurchaseOption(
            title: 'Meal',
            description: 'Food item with meal add-ons',
            price: food.mealPrice,
            selected: _selectedType == PurchaseType.meal,
            onTap: () => setState(
              () => _selectedType = PurchaseType.meal,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quantity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₱${(_price * _quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          if (!food.isAvailable) ...[
            const SizedBox(height: 14),
            const Text(
              'This item is currently unavailable.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: food.isAvailable ? _addToCart : null,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(
              food.isAvailable ? 'Add to Cart' : 'Unavailable',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseOption extends StatelessWidget {
  const _PurchaseOption({
    required this.title,
    required this.description,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(description),
                  ],
                ),
              ),
              Text(
                '₱${price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}