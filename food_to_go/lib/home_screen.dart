import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_type.dart';
import 'models/food_stall.dart';
import 'services/app_data.dart';
import 'screens/cart_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/favorites_screens.dart';
import 'screens/owner_menu_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stall_menu_screen.dart';
import 'widgets/food_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.email,
    required this.accountType,
    required this.storefrontId,
    required this.appData,
    this.profileMetadata = const {},
    this.onRefreshApproval,
  });

  final String email;
  final AccountType accountType;
  final String? storefrontId;
  final Future<void> Function()? onRefreshApproval;
  final AppData appData;
  final Map<String, dynamic> profileMetadata;

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to log out: $error')));
      }
    }
  }

  void _openCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen(appData: appData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (accountType == AccountType.pending ||
        (accountType == AccountType.foodStall && storefrontId == null)) {
      return _PendingApprovalScreen(
        email: email,
        onRefreshApproval: onRefreshApproval,
        onSignOut: () => _signOut(context),
      );
    }

    if (appData.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appData.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load your data from Supabase.'),
                const SizedBox(height: 8),
                Text(appData.loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: appData.retryLoad,
                  child: const Text('Try again'),
                ),
                TextButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (accountType == AccountType.foodStall) {
      final stall = appData.getStall(storefrontId!);

      if (stall == null || !appData.canManageStorefront(stall.id)) {
        return _PendingApprovalScreen(
          email: email,
          onRefreshApproval: onRefreshApproval,
          message:
              'Ask the administrator to verify that your storefront is assigned only to your account.',
          onSignOut: () => _signOut(context),
        );
      }

      return _OwnerDashboard(
        email: email,
        stall: stall,
        appData: appData,
        profileMetadata: profileMetadata,
        onSignOut: () => _signOut(context),
      );
    }

    if (accountType == AccountType.admin) {
      return AdminDashboardScreen(
        appData: appData,
        onSignOut: () => _signOut(context),
      );
    }

    return _CustomerHome(
      email: email,
      appData: appData,
      profileMetadata: profileMetadata,
      onSignOut: () => _signOut(context),
      onOpenCart: () => _openCart(context),
    );
  }
}

class _CustomerHome extends StatelessWidget {
  const _CustomerHome({
    required this.email,
    required this.appData,
    required this.profileMetadata,
    required this.onSignOut,
    required this.onOpenCart,
  });

  final String email;
  final AppData appData;
  final Map<String, dynamic> profileMetadata;
  final VoidCallback onSignOut;
  final VoidCallback onOpenCart;

  void _openStall(BuildContext context, FoodStall stall) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StallMenuScreen(stallId: stall.id, appData: appData),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          email: email,
          profileMetadata: profileMetadata,
          appData: appData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.sizeOf(context).width < 400
            ? null
            : const Icon(Icons.restaurant_menu),
        title: const Text('Food to Go'),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritesScreen(appData: appData),
                ),
              );
            },
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            tooltip: 'Cart',
            onPressed: onOpenCart,
            icon: Badge(
              isLabelVisible: appData.cart.totalItems > 0,
              label: Text('${appData.cart.totalItems}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          IconButton(
            tooltip: 'My profile',
            onPressed: () => _openProfile(context),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Your campus food, made easy.',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Signed in as $email',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fastfood, color: Colors.white, size: 30),
                SizedBox(height: 12),
                Text(
                  'Find your next meal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Browse food stalls and order your favorites.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrdersScreen(appData: appData),
                ),
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('My Orders'),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Available stalls',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('${appData.stalls.length} stalls'),
            ],
          ),
          const SizedBox(height: 12),
          ...appData.stalls.map(
            (stall) => _StallCard(
              stall: stall,
              appData: appData,
              onTap: () => _openStall(context, stall),
            ),
          ),
        ],
      ),
    );
  }
}

class _StallCard extends StatelessWidget {
  const _StallCard({
    required this.stall,
    required this.appData,
    required this.onTap,
  });

  final FoodStall stall;
  final AppData appData;
  final VoidCallback onTap;

  Future<void> _toggleStallLike(BuildContext context) async {
    try {
      await appData.toggleStallLike(stall.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to update your storefront like: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FoodImage(imageUrl: stall.imageUrl, height: 155),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stall.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(stall.description),
                        const SizedBox(height: 5),
                        Text('${stall.menu.length} menu items'),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: appData.hasLiked(stall.id)
                            ? 'Unlike storefront'
                            : 'Like storefront',
                        onPressed: appData.isUpdatingLike(stall.id)
                            ? null
                            : () => _toggleStallLike(context),
                        icon: Icon(
                          appData.hasLiked(stall.id)
                              ? Icons.thumb_up
                              : Icons.thumb_up_alt_outlined,
                        ),
                      ),
                      Text('${appData.likesFor(stall.id)}'),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerDashboard extends StatelessWidget {
  const _OwnerDashboard({
    required this.email,
    required this.stall,
    required this.appData,
    required this.profileMetadata,
    required this.onSignOut,
  });

  final String email;
  final FoodStall stall;
  final AppData appData;
  final Map<String, dynamic> profileMetadata;
  final VoidCallback onSignOut;

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          email: email,
          profileMetadata: profileMetadata,
          appData: appData,
          stall: stall,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Stall Dashboard'),
        actions: [
          IconButton(
            tooltip: 'My profile',
            onPressed: () => _openProfile(context),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Welcome back',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(email),
          const SizedBox(height: 22),
          FoodImage(imageUrl: stall.imageUrl, height: 170),
          const SizedBox(height: 16),
          Text(
            stall.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(stall.description),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: MediaQuery.sizeOf(context).width < 400
                  ? null
                  : const Icon(Icons.restaurant_menu),
              title: const Text('Menu items'),
              subtitle: Text('${stall.menu.length} items'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.thumb_up_alt_outlined),
              title: const Text('Storefront likes'),
              subtitle: Text('${appData.likesFor(stall.id)} likes'),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OwnerMenuScreen(stallId: stall.id, appData: appData),
                ),
              );
            },
            icon: const Icon(Icons.edit_note),
            label: const Text('Manage Menu'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrdersScreen(appData: appData, stallId: stall.id),
              ),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Stall Orders'),
          ),
          const SizedBox(height: 10),
          const Text(
            'You can only manage the storefront assigned to your account.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalScreen extends StatefulWidget {
  const _PendingApprovalScreen({
    required this.email,
    required this.onSignOut,
    this.onRefreshApproval,
    this.message =
        'Your Food Stall account is waiting for administrator approval and storefront assignment.',
  });

  final String email;
  final String message;
  final Future<void> Function()? onRefreshApproval;
  final VoidCallback onSignOut;

  @override
  State<_PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<_PendingApprovalScreen> {
  bool _refreshing = false;
  String? _refreshMessage;

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshMessage = null;
    });
    try {
      await widget.onRefreshApproval!();
      if (mounted) setState(() => _refreshMessage = 'Still awaiting approval.');
    } catch (error) {
      if (mounted) {
        setState(() => _refreshMessage = 'Unable to check approval: $error');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food to Go'),
        actions: [
          IconButton(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 65),
              const SizedBox(height: 18),
              Text(
                'Account Pending',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(widget.message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                widget.email,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.onRefreshApproval != null)
                FilledButton.icon(
                  onPressed: _refreshing ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _refreshing ? 'Checking approval…' : 'Check approval',
                  ),
                ),
              if (_refreshMessage != null)
                Text(_refreshMessage!, textAlign: TextAlign.center),
              OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
