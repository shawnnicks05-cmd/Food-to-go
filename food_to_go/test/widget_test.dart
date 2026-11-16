
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_to_go/account_type.dart';
import 'package:food_to_go/auth_screen.dart';
import 'package:food_to_go/main.dart';
import 'package:food_to_go/home_screen.dart';
import 'package:food_to_go/services/app_data.dart';

void main() {
  test('only USJ-R email addresses are allowed', () {
    expect(isUsjrEmail('student@usjr.edu.ph'), isTrue);
    expect(isUsjrEmail('STUDENT@USJR.EDU.PH'), isTrue);
    expect(isUsjrEmail('student@gmail.com'), isFalse);
    expect(isUsjrEmail('student@usjr.edu.ph.example.com'), isFalse);
  });

  testWidgets('shows login and account creation options', (tester) async {
    await tester.pumpWidget(
      const FoodToGoApp(supabaseConfigured: false),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('USJ-R email'), findsOneWidget);
    expect(find.text('Food stall'), findsNothing);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('Food stall'), findsOneWidget);
    expect(find.text('For students and professors'), findsOneWidget);

    await tester.tap(find.text('Food stall'));
    await tester.pumpAndSettle();

    expect(find.text('For food stall accounts'), findsOneWidget);
  });

  testWidgets('customer home screen displays the signed-in account',
      (tester) async {
    final appData = AppData();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          email: 'student@usjr.edu.ph',
          accountType: AccountType.regular,
          storefrontId: null,
          appData: appData,
        ),
      ),
    );

    expect(find.text('Food to Go'), findsOneWidget);
    expect(find.text('Signed in as student@usjr.edu.ph'), findsOneWidget);
    expect(find.text('Find your next meal'), findsOneWidget);
    expect(find.text('Available stalls'), findsOneWidget);
    expect(find.byTooltip('Log out'), findsOneWidget);
    expect(tester.takeException(), isNull);

    appData.dispose();
  });

  testWidgets('food stall account gets its assigned dashboard',
      (tester) async {
    final appData = AppData();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          email: 'stall@example.com',
          accountType: AccountType.foodStall,
          storefrontId: 'waffle_time',
          appData: appData,
        ),
      ),
    );

    expect(find.text('Food Stall Dashboard'), findsOneWidget);
    expect(find.text('Waffle Time'), findsOneWidget);
    expect(find.text('Manage Menu'), findsOneWidget);
    expect(
      find.text(
        'You can only manage the storefront assigned to your account.',
      ),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);

    appData.dispose();
  });
}
