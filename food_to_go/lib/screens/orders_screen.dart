import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pickup_order.dart';
import '../services/app_data.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.appData, this.stallId});

  final AppData appData;
  final String? stallId;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<PickupOrder>? _orders;
  String? _error;
  bool _loading = false;
  bool _saving = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_saving || ModalRoute.of(context)?.isCurrent != true) return;
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final orders = await widget.appData.loadPickupOrders(
        stallId: widget.stallId,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to load orders: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advanceOrder(PickupOrder order) async {
    final stallId = widget.stallId;
    if (stallId == null || _loading || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.appData.advancePickupOrder(stallId, order);
      if (mounted) await _loadOrders();
    } catch (error) {
      if (!mounted) return;
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Unable to update order: $error')),
          );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stallId == null ? 'My Orders' : 'Stall Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: _loading || _saving ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: orders == null && _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) Text(_error!),
                if (orders?.isEmpty == true && _error == null)
                  const Text('No orders yet.'),
                for (final order in orders ?? <PickupOrder>[])
                  _orderCard(context, order),
              ],
            ),
    );
  }

  Widget _orderCard(BuildContext context, PickupOrder order) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(order.createdAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(order.createdAt),
    );
    final action = order.nextAction;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.stallName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('#${order.id.substring(0, 8)} · $date $time'),
            Text(
              order.statusLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(order.paymentMethod),
            const Divider(),
            for (final item in order.items)
              Text(
                '${item['quantity']} × ${item['name']} (${item['type']}) · ₱${(item['subtotal'] as num).toStringAsFixed(2)}',
              ),
            if (widget.stallId != null && action != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving || _loading
                    ? null
                    : () => _advanceOrder(order),
                child: Text(action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
