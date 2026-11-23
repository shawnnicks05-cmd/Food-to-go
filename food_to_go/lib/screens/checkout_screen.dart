import 'package:flutter/material.dart';

import '../services/app_data.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.appData});

  final AppData appData;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Cash on Pickup';
  bool _placingOrder = false;
  String? _error;

  Future<void> _placeOrder() async {
    if (widget.appData.cart.items.isEmpty) return;

    setState(() {
      _placingOrder = true;
      _error = null;
    });
    final items = widget.appData.cart.items.toList();

    try {
      final order = await widget.appData.placeOrder(
        items: items,
        paymentMethod: _paymentMethod,
      );
      widget.appData.cart.clearCart();

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _OrderConfirmationScreen(
            order: order,
            appData: widget.appData,
            paymentMethod: _paymentMethod,
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to place order: $error');
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...cart.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.food.name),
              subtitle: Text('${item.purchaseLabel} × ${item.quantity}'),
              trailing: Text('₱${item.subtotal.toStringAsFixed(2)}'),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Method',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          RadioGroup<String>(
            groupValue: _paymentMethod,
            onChanged: (value) {
              if (value != null) setState(() => _paymentMethod = value);
            },
            child: const Column(
              children: [
                RadioListTile<String>(
                  value: 'Cash on Pickup',
                  title: Text('Cash on Pickup'),
                ),
                RadioListTile<String>(
                  value: 'Pay at Stall',
                  title: Text('Pay at Stall'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _placingOrder ? null : _placeOrder,
            child: _placingOrder
                ? const CircularProgressIndicator()
                : const Text('Place Order'),
          ),
          const SizedBox(height: 10),
          const Text(
            'No real payment will be collected.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderConfirmationScreen extends StatelessWidget {
  const _OrderConfirmationScreen({
    required this.order,
    required this.appData,
    required this.paymentMethod,
  });

  final PlacedOrder order;
  final AppData appData;
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
                'Your order has been saved.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text('Order #${order.id.substring(0, 8)}'),
              Text('Items: ${order.itemCount}'),
              Text('Payment: $paymentMethod'),
              Text('Total: ₱${order.total.toStringAsFixed(2)}'),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrdersScreen(appData: appData),
                  ),
                ),
                child: const Text('Track order'),
              ),
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
