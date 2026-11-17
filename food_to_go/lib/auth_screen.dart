import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_type.dart';
import 'home_screen.dart';
import 'services/app_data.dart';

bool isUsjrEmail(String email) =>
    email.trim().toLowerCase().endsWith('@usjr.edu.ph');

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.supabaseConfigured,
    required this.appData,
  });

  final bool supabaseConfigured;
  final AppData appData;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  StreamSubscription<AuthState>? _authSubscription;

  bool _creatingAccount = false;
  bool _loading = false;
  bool _obscurePassword = true;

  AccountType _selectedType = AccountType.regular;
  User? _user;

  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();

    if (widget.supabaseConfigured) {
      final auth = Supabase.instance.client.auth;
      _user = auth.currentUser;
      unawaited(widget.appData.setUser(_user?.id));

      _authSubscription = auth.onAuthStateChange.listen((state) {
        if (!mounted) return;
        final user = state.session?.user;
        setState(() => _user = user);
        unawaited(widget.appData.setUser(user?.id));
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    if (_creatingAccount &&
        _selectedType == AccountType.regular &&
        !isUsjrEmail(email)) {
      return 'Regular accounts must use an @usjr.edu.ph email.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.supabaseConfigured) {
      setState(() {
        _error = 'Authentication is not configured for this application.';
        _success = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();

      if (_creatingAccount) {
        final response = await auth.signUp(
          email: email,
          password: _passwordController.text,
          emailRedirectTo: kIsWeb ? Uri.base.origin : null,
          data: {
            'requested_account_type': _selectedType == AccountType.foodStall
                ? 'foodstall'
                : 'regular',
          },
        );

        if (!mounted) return;

        if (response.session != null) {
          setState(() => _user = response.session!.user);
        } else {
          setState(() {
            _success =
                'Account request submitted. Check your email to confirm your account. Food Stall accounts require administrator approval.';
          });
        }
      } else {
        final response = await auth.signInWithPassword(
          email: email,
          password: _passwordController.text,
        );

        if (!mounted) return;
        setState(() => _user = response.user);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to connect: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) {
      return HomeScreen(
        email: _user!.email ?? '',
        accountType: AccountTypeInfo.fromUser(_user!),
        storefrontId: assignedStorefrontId(_user!),
        appData: widget.appData,
        profileMetadata: _user!.userMetadata ?? const {},
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _buildAuthForm(Theme.of(context).colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.restaurant, size: 32, color: colors.primary),
        ),
        const SizedBox(height: 24),
        Text(
          _creatingAccount ? 'Create your account' : 'Welcome back',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _creatingAccount
              ? 'Choose your account type and enter your email address.'
              : 'Sign in using your registered email address.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        if (_creatingAccount) ...[
          SegmentedButton<AccountType>(
            segments: const [
              ButtonSegment<AccountType>(
                value: AccountType.regular,
                label: Text('Regular'),
              ),
              ButtonSegment<AccountType>(
                value: AccountType.foodStall,
                label: Text('Food stall'),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: _loading
                ? null
                : (selection) {
                    setState(() => _selectedType = selection.first);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            _selectedType == AccountType.regular
                ? 'For students and professors (USJ-R email required)'
                : 'For food stall accounts (any valid email)',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Email address',
                  hintText:
                      _creatingAccount && _selectedType == AccountType.regular
                      ? 'name@usjr.edu.ph'
                      : 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: _creatingAccount
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: [
                  _creatingAccount
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password.';
                  }
                  if (_creatingAccount && value.length < 8) {
                    return 'Use at least 8 characters.';
                  }
                  return null;
                },
              ),
              if (_creatingAccount) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              if (_success != null) ...[
                const SizedBox(height: 16),
                Text(_success!),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_creatingAccount ? 'Create Account' : 'Log in'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _creatingAccount = !_creatingAccount;
                          _selectedType = AccountType.regular;
                          _error = null;
                          _success = null;
                        });
                      },
                child: Text(
                  _creatingAccount
                      ? 'Already have an account? Log in'
                      : 'New here? Create an account',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
