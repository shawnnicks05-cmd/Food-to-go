# Food to Go

Food to Go is a Flutter-based food ordering application for the University of San Jose-Recoletos (USJ-R). It allows users to create accounts and sign in through Supabase Authentication.

The application supports separate account types for Regular Users, Food Stall Owners, and Administrators. Each account type has a different level of access and a corresponding dashboard.

Regular users can browse food stalls, view menus, customize food selections, manage their shopping cart, and save favorite food items. Food stall owners can access their assigned storefront and manage its menu.

The application is currently a functional prototype that combines Supabase Authentication with locally managed sample application data.

## Features

### Authentication and Account Management

- **Supabase Authentication** – Supports account registration and login through Supabase.
- **USJ-R Email Restriction** – Regular user accounts are restricted to valid `@usjr.edu.ph` email addresses.
- **Account Types** – Supports Regular, Food Stall, and Admin accounts.
- **Food Stall Approval** – Food stall accounts require administrator approval and storefront assignment before accessing their dashboard.
- **Role-Based Navigation** – Directs users to the appropriate dashboard based on their account type.

### Regular User Features

- **Food Stall Browsing** – Browse available food stalls, including Waffle Time, Burp'nGo, and Coffee Shop.
- **Food Menus** – View food products with descriptions, images, and prices.
- **Product Customization** – Select available purchase types, such as Solo or Meal.
- **Quantity Selection** – Choose the desired quantity of each food item.
- **Shopping Cart** – Review selected products, purchase types, quantities, prices, and subtotals.
- **Favorites** – Save food items to a personal favorites list and remove them when desired.
- **Storefront Likes** – Like food stalls and view their current like counts.
- **Order Review** – Review selected items and the calculated cart total before proceeding with the available checkout flow.

### Food Stall Owner Features

- **Dedicated Dashboard** – Provides a separate dashboard for food stall accounts.
- **Assigned Storefront** – Each approved food stall account is associated with a specific storefront.
- **Menu Management** – Access the menu management screen for the assigned storefront.
- **Storefront Information** – View the assigned stall's information and like count.
- **Access Restriction** – Food stall owners are limited to managing their assigned storefront.

### Administrator Account

- **Admin Account Type** – Supports administrator account identification.
- **Protected Role Assignment** – Administrator privileges should be assigned through trusted Supabase app metadata rather than public account registration.
- **Account Approval** – Administrator approval and storefront assignment are part of the food stall account workflow.

The full administrator dashboard and management functions are not yet implemented.

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Application programming language |
| Supabase Auth | User registration and authentication |
| Supabase | Backend platform and future database integration |
| Material Design | Application interface components |

## Configure Supabase

1. Create or open your Supabase project.
2. In the project dashboard, copy the project URL and publishable key (or legacy anon key).
3. Run the application with the following command:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The Supabase URL and publishable key are client configuration values. Never place a Supabase service-role key inside the Flutter application.

For legacy projects, the anon key can also be supplied through `SUPABASE_PUBLISHABLE_KEY`.

4. To enforce the USJ-R email restriction during account creation, run `supabase/allow_usjr_email.sql` in the Supabase SQL Editor.
5. In Supabase, navigate to **Authentication → Hooks** and configure the **Before User Created** hook to use `public.allow_usjr_email`.
6. In **Authentication → Providers → Email**, enable email confirmations if users should verify their email addresses.

The application performs email validation during registration. The database hook provides an additional server-side restriction for account creation.

## Account Types and Storefront Assignment

Food to Go supports three account types:

| Account Type | Description |
|---|---|
| Regular | For students and professors who want to browse and order food. |
| Food Stall | For canteen vendors who manage their assigned storefront and menu. |
| Admin | For administrators responsible for account approval and management. |

### Regular Accounts

Regular accounts can be created through the public registration screen using a valid USJ-R email address.

Example account metadata:

```json
{
  "account_type": "regular"
}
```

### Food Stall Accounts

Food stall users can register using a valid email address. However, registration alone does not grant access to a storefront dashboard.

A food stall account must first be approved and assigned a storefront by an administrator.

Example protected app metadata:

```json
{
  "account_type": "foodstall",
  "storefront_id": "waffle_time"
}
```

Available storefront identifiers:

- `waffle_time`
- `burpngo`
- `coffee_shop`

The `storefront_id` determines which food stall the account can manage.

### Administrator Accounts

Administrator accounts are assigned by an authorized developer or administrator. They cannot be selected through public registration.

Example protected app metadata:

```json
{
  "account_type": "admin"
}
```

**Security note:** Account roles and storefront permissions should be enforced using trusted Supabase app metadata and Row Level Security (RLS) policies. Client-side account selection should only control application navigation and must not be treated as the security boundary.

## Application Dashboards

### Regular User Dashboard

The regular-user dashboard serves as the main screen for customers.

It includes:

- Food stall listings.
- Storefront information.
- Storefront like buttons and like counts.
- Favorites navigation.
- Shopping cart navigation with an item count indicator.
- Access to individual food stall menus.

Selecting a food stall opens its corresponding menu screen.

The current sample storefronts are:

1. Waffle Time
2. Burp'nGo
3. Coffee Shop

### Food Stall Owner Dashboard

Approved food stall accounts are directed to a separate dashboard.

The dashboard displays:

- Assigned storefront information.
- Storefront image and description.
- Number of menu items.
- Storefront like count.
- Menu management navigation.

The owner dashboard uses the assigned `storefrontId` to identify the storefront the account is allowed to manage.

Accounts without an approved storefront assignment are directed to a pending approval screen.

### Pending Approval Screen

Food stall accounts without an approved storefront assignment cannot access the owner dashboard.

Instead, the application displays an account pending message explaining that administrator approval and storefront assignment are required.

This prevents unassigned food stall accounts from accessing menu management through the normal application navigation.

## Food Stall Menus and Product Selection

Each food stall has its own menu screen.

Regular users can:

1. Select a food stall from the home dashboard.
2. Browse its available food products.
3. View product images and descriptions.
4. Open a product's detail screen.
5. Select a purchase type, such as **Solo** or **Meal**, when available.
6. Adjust the desired quantity.
7. Add the selected product to the shopping cart.

The application tracks purchase types and quantities separately so that different versions of the same product can be represented correctly in the cart.

Food availability and menu information are managed through the application's current data layer.

## Favorites and Storefront Likes

Food to Go includes two separate interaction features.

### Food Favorites

Regular users can save food items to their favorites list.

The Favorites screen allows users to:

- View saved food items.
- View product images and prices.
- Open a saved item to view its product details.
- Remove an item from the favorites list.

The Favorites screen uses the shared application data instance so that favorite changes are reflected in the application interface.

### Storefront Likes

Users can like individual food stalls from the regular-user dashboard.

The application displays the current like count for each storefront.

Storefront likes are separate from food favorites: favorites are associated with individual food products, while likes are associated with food stalls.

## Shopping Cart and Order Flow

The shopping cart displays the products selected by the user.

It includes:

- Product name.
- Selected purchase type.
- Quantity.
- Unit price.
- Subtotal.
- Overall cart total.

Products with different purchase types are treated as separate cart entries.

Cart operations are handled through the cart service and shared application state.

The current implementation uses in-memory data. Cart contents are not yet permanently stored in Supabase, so they may reset when the application is restarted.

The checkout flow is intended for prototype testing. Actual payment processing and complete backend order handling are not yet integrated.

## Menu Management

Food stall owners can access the menu management screen through their assigned dashboard.

The application data layer provides operations for:

- Adding food items.
- Updating existing food items.
- Deleting food items.
- Updating food availability.

Storefront ownership is determined by the assigned storefront ID. The owner dashboard passes the shared application data and assigned stall information to the menu management screen.

The current implementation manages sample data locally. Persistent menu updates and server-side ownership enforcement are future integration tasks.

## Project Structure

The application follows a modular folder structure that separates data models, repositories, services, screens, and reusable widgets.

```text
lib/
│
├── main.dart
├── auth_screen.dart
├── home_screen.dart
├── account_type.dart
│
├── models/
│   ├── food_item.dart
│   ├── food_stall.dart
│   └── cart_item.dart
│
├── repositories/
│   ├── stall_repository.dart
│   └── mock_stall_repository.dart
│
├── services/
│   ├── app_data.dart
│   └── cart_service.dart
│
├── widgets/
│   └── food_image.dart
│
└── screens/
    ├── stall_menu_screen.dart
    ├── product_detail_screen.dart
    ├── cart_screen.dart
    ├── favorites_screen.dart
    └── owner_menu_screen.dart
```

### Folder Responsibilities

| File / Folder | Responsibility |
|---|---|
| `models/` | Contains the data structures for food items, food stalls, and cart entries. |
| `repositories/` | Defines the stall repository contract and provides sample stall data through a mock implementation. |
| `services/app_data.dart` | Maintains shared application data, including stalls, favorites, likes, and menu operations. |
| `services/cart_service.dart` | Handles shopping cart operations, quantities, and price calculations. |
| `widgets/` | Contains reusable interface components, such as food images. |
| `screens/` | Contains the individual menu, product detail, cart, favorites, and owner menu management screens. |
| `main.dart` | Initializes the application and its dependencies. |
| `auth_screen.dart` | Handles account registration and authentication. |
| `home_screen.dart` | Directs users to the appropriate dashboard based on their account type and storefront assignment. |
| `account_type.dart` | Defines the supported account types and related role handling. |

## Architecture and Design Principles

Food to Go uses a separation-of-concerns approach to keep its components organized and maintainable.

### Shared Application State

The application uses `AppData` as a shared state manager.

It provides access to the application's current stall data and coordinates updates to features such as:

- Food favorites.
- Storefront likes.
- Menu operations.
- Food availability.
- Shopping cart updates.

Screens receive the shared `AppData` instance instead of creating unrelated copies of the application state.

This allows changes made in one screen to be reflected in other screens that use the same instance.

### SOLID Principles

The application is organized around the following SOLID principles:

- **Single Responsibility Principle (SRP)** – Models, repositories, services, and screens have separate responsibilities.
- **Open/Closed Principle (OCP)** – The repository abstraction allows different data implementations to be introduced without redesigning the entire interface.
- **Liskov Substitution Principle (LSP)** – Repository implementations should remain interchangeable when they follow the repository contract.
- **Interface Segregation Principle (ISP)** – Components should depend only on the operations relevant to their responsibilities.
- **Dependency Inversion Principle (DIP)** – Repository-dependent components should rely on abstractions rather than being tightly coupled to a specific data implementation.

## Running the Application

Make sure Flutter and the required dependencies are installed.

From the project directory, run:

```bash
flutter pub get
```

To check for code issues:

```bash
flutter analyze
```

To run the automated tests:

```bash
flutter test
```

To launch the application with Supabase configuration:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## Current Implementation and Future Integration

The application currently combines Supabase Authentication with locally managed sample food ordering data.

| Component | Current Implementation |
|---|---|
| User authentication | Supabase Auth |
| Email restriction | USJ-R email validation and server-side account creation hook |
| Account types | Regular, Food Stall, Admin |
| Food stall approval | Pending state and storefront assignment handling |
| Regular-user dashboard | Implemented |
| Food stall owner dashboard | Implemented |
| Administrator dashboard | Not yet implemented |
| Food stall listings | Sample application data |
| Food menus | Sample application data |
| Product customization | Solo and Meal selection |
| Quantity selection | Implemented |
| Shopping cart | In-memory cart service |
| Favorites | In-memory application state |
| Storefront likes | In-memory application state |
| Menu management | Local application data operations |
| Order processing | Not yet connected to a persistent backend |
| Payment processing | Not implemented |
| Incoming food-stall orders | Not yet integrated with a backend |

### Future Improvements

The following improvements can be implemented in future development:

- Connect food stall listings and menu products to Supabase.
- Store food favorites and storefront likes in the database.
- Persist menu changes made by food stall owners.
- Implement administrator approval and storefront assignment tools.
- Store customer carts and orders in Supabase.
- Implement complete order submission and order status tracking.
- Allow food stall owners to receive and manage incoming orders.
- Implement a best-selling products feature using actual order records.
- Implement payment integration if required.
- Configure and test Supabase Row Level Security policies for customer, owner, and administrator access.

**Note:** Food to Go currently uses Supabase Authentication alongside local sample application data. Authentication, account-type navigation, and the prototype's customer and owner interfaces should be retained as the application moves toward database integration. Features that still rely on in-memory data should not be considered permanently stored or synchronized between devices.

## Screen Flow and Navigation

Food to Go uses separate navigation flows depending on the authenticated user's account type. After successful login, the application checks the user's account information and determines which dashboard or screen should be displayed.

### Overall Application Flow

```text
Application Launch
       |
       v
Authentication Screen
(Login / Create Account)
       |
       v
Account Type and Access Check
       |
       +-----------------------+
       |           |           |
       v           v           v
    Regular    Food Stall    Admin
       |           |           |
       v           v           v
 Customer Home  Approval    Admin Placeholder
       |         Check       (Not Implemented)
       |           |
       |           +------------------+
       |           |                  |
       |           v                  v
       |     Pending Approval    Owner Dashboard
       |                              |
       |                              v
       |                         Manage Menu
       |
       +---------------------------+
       |             |
       v             v
   Stall Menu     Favorites
       |
       v
 Product Details
       |
       v
 Add to Cart
       |
       v
 Shopping Cart
       |
       v
 Review Order
```

### 1. Authentication Flow

The application starts at the authentication screen, where users can log in or create an account.

- Regular users register using a valid USJ-R email address.
- Food stall users can register using a valid email address.
- Administrator accounts are assigned through trusted administrative configuration.
- After authentication, the application checks the account type and storefront assignment.

### 2. Regular User Navigation

Regular users are directed to the Customer Home screen after successful authentication.

The Customer Home screen provides access to the available food stalls, favorites, and shopping cart.

**Navigation Flow:**

```text
Customer Home
    |
    +----> Stall Menu
    |          |
    |          v
    |     Product Details
    |          |
    |          v
    |      Add to Cart
    |          |
    |          v
    |      Shopping Cart
    |
    +----> Favorites
    |          |
    |          v
    |     Product Details
    |
    +----> Shopping Cart
```

The Customer Home screen also allows users to like food stalls and view their like counts.

### 3. Food Stall Owner Navigation

Food stall accounts follow a separate navigation flow.

```text
Food Stall Login
       |
       v
Storefront Assignment Check
       |
       +--------------------------+
       |                          |
       v                          v
No Assignment               Assigned Storefront
       |                          |
       v                          v
Pending Approval             Owner Dashboard
                                  |
                                  v
                              Manage Menu
                                  |
                                  v
                           Menu Management
```

The application checks the assigned storefront before displaying the owner dashboard. This ensures that the owner accesses the menu management screen associated with their assigned storefront.

### 4. Administrator Navigation

Administrator accounts are identified separately from regular and food stall accounts.

The administrator dashboard and its management operations are not yet implemented in the current prototype.

The intended future workflow is:

```text
Admin Login
     |
     v
Admin Dashboard
     |
     v
Review Food Stall Accounts
     |
     v
Approve Food Stall Account
     |
     v
Assign Storefront
```

### 5. Navigation and Shared Application State

The application uses Flutter's navigation system to move between screens.

The shared `AppData` instance provides access to application data across the customer and owner screens. This allows changes to favorites, storefront likes, cart contents, and menu information to be reflected in screens using the same application state.

The current implementation primarily uses in-memory application data. Persistent synchronization through Supabase is a future integration task.

