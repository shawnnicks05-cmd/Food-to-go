import 'package:flutter/material.dart';

import '../services/app_data.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.appData,
  });

  final AppData appData;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Cash on Pickup';
  bool _placingOrder = false;

  Future<void> _placeOrder() async {
    if (widget.appData.cart.items.isEmpty) return;

    setState(() => _placingOrder = true);

    // Prototype only: simulate a successful order.
    final items = widget.appData.cart.items.toList();
    final total = widget.appData.cart.totalPrice;

    for (final item in items) {
      final food = widget.appData.getFood(item.food.id);
      if (food != null) {
        food.orderCount += item.quantity;
      }
    }

    widget.appData.cart.clearCart();

    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _OrderConfirmationScreen(
          total: total,
          itemCount: items.fold(
            0,
            (sum, item) => sum + item.quantity,
          ),
          paymentMethod: _paymentMethod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.appData.cart;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...cart.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.food.name),
              subtitle: Text(
                '${item.purchaseLabel} × ${item.quantity}',
              ),
              trailing: Text(
                '₱${item.subtotal.toStringAsFixed(2)}',
              ),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '₱${cart.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          RadioListTile<String>(
            value: 'Cash on Pickup',
            groupValue: _paymentMethod,
            title: const Text('Cash on Pickup'),
            onChanged: (value) {
              if (value != null) {
                setState(() => _paymentMethod = value);
              }
            },
          ),
          RadioListTile<String>(
            value: 'Pay at Stall',
            groupValue: _paymentMethod,
            title: const Text('Pay at Stall'),
            onChanged: (value) {
              if (value != null) {
                setState(() => _paymentMethod = value);
              }
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _placingOrder ? null : _placeOrder,
            child: _placingOrder
                ? const CircularProgressIndicator()
                : const Text('Place Order'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Demo checkout only. No real payment will be collected.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderConfirmationScreen extends StatelessWidget {
  const _OrderConfirmationScreen({
    required this.total,
    required this.itemCount,
    required this.paymentMethod,
  });

  final double total;
  final int itemCount;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 76,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Order placed!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your demo order has been recorded successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text('Items: $itemCount'),
              Text('Payment: $paymentMethod'),
              Text('Total: ₱${total.toStringAsFixed(2)}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}