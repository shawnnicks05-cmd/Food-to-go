import 'package:supabase_flutter/supabase_flutter.dart';

enum AccountType {
  regular,
  foodStall,
  admin,
  pending,
}

extension AccountTypeInfo on AccountType {
  String get label {
    switch (this) {
      case AccountType.regular:
        return 'Regular';
      case AccountType.foodStall:
        return 'Food Stall';
      case AccountType.admin:
        return 'Admin';
      case AccountType.pending:
        return 'Pending Approval';
    }
  }

  static AccountType fromUser(User user) {
    final role = user.appMetadata['account_type'];

    if (role == 'admin') return AccountType.admin;
    if (role == 'foodstall') return AccountType.foodStall;
    if (role == 'regular') return AccountType.regular;

    // This is only a registration request, not an approved role.
    if (user.userMetadata?['requested_account_type'] == 'foodstall') {
      return AccountType.pending;
    }

    return AccountType.regular;
  }
}

String? assignedStorefrontId(User user) {
  final value = user.appMetadata['storefront_id'];
  return value is String && value.isNotEmpty ? value : null;
}