# Food to Go

Food to Go is a campus pickup-ordering app for USJ-R, built with Flutter and Supabase.

## How it works

- **Customers** sign up with a USJ-R email, browse menus, and place pickup orders. **My Orders** shows each stall's status, including when food is ready for pickup.
- **Stall owners** request an account and wait for an administrator to assign a storefront. They manage their menu and process orders from **Stall Orders**.
- **Administrators** approve stall accounts and assign unassigned storefronts.

An order can include food from several stalls. Each stall sees its own items and moves them through **Order placed → Preparing → Ready for pickup → Picked up**. The orders screen checks for updates every 15 seconds while open and also has a refresh button. Customers pay at pickup.

## Start here in the code

| File | What it does |
|---|---|
| `lib/auth_screen.dart` | Handles signup, login, and session changes. |
| `lib/home_screen.dart` | Displays the dashboard for the signed-in account. |
| `lib/screens/checkout_screen.dart` | Sends the cart to Supabase and shows the order number. |
| `lib/screens/orders_screen.dart` | Shows order status to customers and order actions to stall owners. |
| `lib/models/pickup_order.dart` | Converts the database response into a Dart order model. |
| `lib/services/app_data.dart` | Reads and writes app data through Supabase. |
| `supabase/schema.sql` | Creates the tables, checks access, and handles checkout and status updates. |

To follow what happens when an owner taps **Mark ready**, start with `_advanceOrder` in the orders screen. It calls `advancePickupOrder` in `AppData`, which sends the order ID and current status to Supabase. Supabase checks storefront ownership, updates the status, and the screen reloads the order list.

## Setup and tests

Follow the [Supabase setup guide](supabase/README.md) to apply the database schema, create an administrator account, and configure web deployment. Apply the updated schema before deploying changes that use the order screens.

```powershell
flutter pub get
flutter run -d chrome
flutter test
```
