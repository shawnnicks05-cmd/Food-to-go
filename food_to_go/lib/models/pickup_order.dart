class PickupOrder {
  PickupOrder.fromMap(Map<String, dynamic> row)
    : id = row['order_id'] as String,
      stallName = row['stall_name'] as String,
      createdAt = DateTime.parse(row['created_at'] as String).toLocal(),
      paymentMethod = row['payment_method'] as String,
      status = row['status'] as String,
      items = (row['items'] as List).cast<Map<String, dynamic>>();

  final String id;
  final String stallName;
  final DateTime createdAt;
  final String paymentMethod;
  final String status;
  final List<Map<String, dynamic>> items;

  String get statusLabel => switch (status) {
    'placed' => 'Order placed',
    'preparing' => 'Preparing',
    'ready' => 'Ready for pickup',
    'completed' => 'Picked up',
    _ => status,
  };

  String? get nextAction => switch (status) {
    'placed' => 'Start preparing',
    'preparing' => 'Mark ready',
    'ready' => 'Confirm pickup',
    _ => null,
  };
}
