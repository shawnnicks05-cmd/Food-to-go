import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_to_go/account_type.dart';
import 'package:food_to_go/auth_screen.dart';
import 'package:food_to_go/main.dart';
import 'package:food_to_go/home_screen.dart';
import 'package:food_to_go/models/food_stall.dart';
import 'package:food_to_go/services/app_data.dart';

void main() {
  test('USJ-R email detection is case-insensitive and exact', () {
    expect(isUsjrEmail('student@usjr.edu.ph'), isTrue);
    expect(isUsjrEmail('STUDENT@USJR.EDU.PH'), isTrue);
    expect(isUsjrEmail('student@gmail.com'), isFalse);
    expect(isUsjrEmail('student@usjr.edu.ph.example.com'), isFalse);
  });

  testWidgets('shows login and account creation options', (tester) async {
    await tester.pumpWidget(const FoodToGoApp(supabaseConfigured: false));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Sign in using your registered email address.'),
      findsOneWidget,
    );
    expect(find.text('Food stall'), findsNothing);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('Food stall'), findsOneWidget);
    expect(
      find.text('For students and professors (USJ-R email required)'),
      findsOneWidget,
    );

    await tester.tap(find.text('Food stall'));
    await tester.pumpAndSettle();

    expect(
      find.text('For food stall accounts (any valid email)'),
      findsOneWidget,
    );
  });

  testWidgets('customer home and profile fit a narrow mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appData = AppData.withStalls([]);
    addTearDown(appData.dispose);

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
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    final phone = find.widgetWithText(TextFormField, 'Phone number');
    await tester.enterText(phone, '+63 call 912-345-6789');
    expect(
      tester.widget<TextFormField>(phone).controller!.text,
      '+63  912-345-6789',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer home screen displays the signed-in account', (
    tester,
  ) async {
    final appData = AppData.withStalls([]);

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
    expect(find.byTooltip('My profile'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('Save personal profile'), findsOneWidget);

    appData.dispose();
  });

  testWidgets('food stall account gets its assigned dashboard', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appData = AppData.withStalls([
      FoodStall(
        id: 'waffle_time',
        name: 'Waffle Time',
        description: '',
        imageUrl: '',
        menu: [],
      ),
    ]);

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
    expect(find.byTooltip('My profile'), findsOneWidget);
    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Storefront details'), findsOneWidget);
    expect(find.text('Save storefront details'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('You can only manage the storefront assigned to your account.'),
      100,
    );
    expect(
      find.text('You can only manage the storefront assigned to your account.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Manage Menu'), 100);
    await tester.tap(find.text('Manage Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    expect(find.text('Choose and upload image'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    appData.dispose();
  });

  testWidgets('admin account opens approval dashboard', (tester) async {
    final appData = AppData.withStalls([]);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          email: 'admin@example.com',
          accountType: AccountType.admin,
          storefrontId: null,
          appData: appData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Administrator Dashboard'), findsOneWidget);
    expect(find.text('Food Stall approval requests'), findsOneWidget);
    expect(tester.takeException(), isNull);

    appData.dispose();
  });
}
