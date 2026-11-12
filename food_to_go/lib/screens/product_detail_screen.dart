import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/food_stall.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/food_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final FoodItem food;
  final FoodStall stall;
  final CartService cart;

  const ProductDetailScreen({
    super.key,
    required this.food,
    required this.stall,
    required this.cart,
  });

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  PurchaseType _selectedType = PurchaseType.solo;

  int _quantity = 1;

  double get _selectedPrice {
    return _selectedType == PurchaseType.meal
        ? widget.food.mealPrice
        : widget.food.soloPrice;
  }

  double get _totalPrice => _selectedPrice * _quantity;

  void _addToCart() {
    widget.cart.addItem(
      widget.food,
      _selectedType,
      _quantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.food.name} added to cart!',
        ),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
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
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FoodImage(
              imageUrl: food.imageUrl,
              height: 230,
            ),

            const SizedBox(height: 20),

            Text(
              food.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              food.description,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Choose your order',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _PurchaseOption(
              title: 'Solo',
              description: 'Food item only',
              price: food.soloPrice,
              selected:
                  _selectedType == PurchaseType.solo,
              onTap: () {
                setState(() {
                  _selectedType = PurchaseType.solo;
                });
              },
            ),

            const SizedBox(height: 12),

            _PurchaseOption(
              title: 'Meal',
              description: 'Food item with meal add-ons',
              price: food.mealPrice,
              selected:
                  _selectedType == PurchaseType.meal,
              onTap: () {
                setState(() {
                  _selectedType = PurchaseType.meal;
                });
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _quantity > 1
                      ? () {
                          setState(() => _quantity--);
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton.filledTonal(
                  onPressed: () {
                    setState(() => _quantity++);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    '₱${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _addToCart,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Add to Cart'),
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
  final String title;
  final String description;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  const _PurchaseOption({
    required this.title,
    required this.description,
    required this.price,
    required this.selected,
    required this.onTap,
  });

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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '₱${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}