import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_to_go/models/pickup_order.dart';
import 'package:food_to_go/screens/orders_screen.dart';
import 'package:food_to_go/services/app_data.dart';

class TestOrderData extends AppData {
  String status = 'preparing';

  @override
  Future<List<PickupOrder>> loadPickupOrders({String? stallId}) async => [
    PickupOrder.fromMap({
      'order_id': '12345678-1234-1234-1234-123456789012',
      'stall_name': 'Campus Cafe',
      'created_at': '2026-11-23T09:00:00Z',
      'payment_method': 'Cash on Pickup',
      'status': status,
      'items': [
        {'name': 'Coffee', 'type': 'solo', 'quantity': 1, 'subtotal': 50},
      ],
    }),
  ];

  @override
  Future<void> advancePickupOrder(String stallId, PickupOrder order) async {
    expect(stallId, 'cafe');
    expect(order.status, 'preparing');
    status = 'ready';
  }
}

void main() {
  testWidgets('stall owners can mark an order ready for pickup', (
    tester,
  ) async {
    final appData = TestOrderData();
    addTearDown(appData.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: OrdersScreen(appData: appData, stallId: 'cafe'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark ready'));
    await tester.pumpAndSettle();

    expect(find.text('Ready for pickup'), findsOneWidget);
    expect(find.text('Confirm pickup'), findsOneWidget);
  });

  testWidgets('customers can refresh status and see pickup readiness', (
    tester,
  ) async {
    final appData = TestOrderData();
    addTearDown(appData.dispose);
    await tester.pumpWidget(MaterialApp(home: OrdersScreen(appData: appData)));
    await tester.pumpAndSettle();
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Mark ready'), findsNothing);

    appData.status = 'ready';
    await tester.tap(find.byTooltip('Refresh orders'));
    await tester.pumpAndSettle();

    expect(find.text('Ready for pickup'), findsOneWidget);
    expect(find.text('Confirm pickup'), findsNothing);
  });
}
