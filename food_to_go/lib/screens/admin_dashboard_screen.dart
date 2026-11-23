import 'package:flutter/material.dart';

import '../models/food_stall.dart';
import '../services/app_data.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.appData,
    required this.onSignOut,
  });

  final AppData appData;
  final VoidCallback onSignOut;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<PendingStallAccount> _accounts = [];
  final Map<String, String?> _selectedStalls = {};
  List<FoodStall> _availableStalls = [];
  bool _approving = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accounts = await widget.appData.loadPendingStallAccounts();
      final availableIds = await widget.appData.loadAvailableStorefrontIds();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _availableStalls = widget.appData.stalls
            .where((stall) => availableIds.contains(stall.id))
            .toList();
        _selectedStalls.removeWhere(
          (userId, stallId) =>
              !availableIds.contains(stallId) ||
              !accounts.any((account) => account.userId == userId),
        );
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(PendingStallAccount account) async {
    final stallId = _selectedStalls[account.userId];
    if (stallId == null) {
      setState(
        () => _error =
            'Select an available storefront before approving the account.',
      );
      return;
    }

    setState(() {
      _approving = true;
      _error = null;
    });
    try {
      await widget.appData.approveFoodStallAccount(
        userId: account.userId,
        stallId: stallId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${account.email} was approved.')),
        );
      await _loadAccounts();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to approve account: $error');
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh pending accounts',
            onPressed: _loading || _approving ? null : _loadAccounts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (!_approving) await _loadAccounts();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Food Stall approval requests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_accounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('There are no pending Food Stall accounts.'),
                    ),
                  if (_availableStalls.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'No unassigned storefronts are available. Add a stall in '
                        'Supabase Table Editor before approving accounts.',
                      ),
                    ),
                  ..._accounts.map(
                    (account) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              account.email,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedStalls[account.userId],
                              decoration: const InputDecoration(
                                labelText: 'Assign storefront',
                              ),
                              isExpanded: true,
                              items: _availableStalls
                                  .map(
                                    (stall) => DropdownMenuItem(
                                      value: stall.id,
                                      child: Text(
                                        stall.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _approving || _availableStalls.isEmpty
                                  ? null
                                  : (stallId) {
                                      setState(
                                        () => _selectedStalls[account.userId] =
                                            stallId,
                                      );
                                    },
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed:
                                  _approving ||
                                      _selectedStalls[account.userId] == null
                                  ? null
                                  : () => _approve(account),
                              child: const Text('Approve account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
