import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

bool isUsjrEmail(String email) =>
    email.trim().toLowerCase().endsWith('@usjr.edu.ph');

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;

  bool _isCreatingAccount = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;
  User? _user;

  @override
  void initState() {
    super.initState();
    if (widget.supabaseConfigured) {
      final auth = Supabase.instance.client.auth;
      _user = auth.currentUser;
      _authSubscription = auth.onAuthStateChange.listen((state) {
        if (mounted) {
          setState(() {
            _user = state.session?.user;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      if (_isCreatingAccount) {
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          if (response.session != null) {
            setState(() => _user = response.session!.user);
          } else {
            setState(() {
              _successMessage =
                  'Check your USJ-R email for a confirmation link to finish creating your account.';
            });
          }
        }
      } else {
        final response = await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          final user = response.session?.user ?? response.user;
          if (user != null) {
            setState(() => _user = user);
          }
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to connect: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your USJ-R email address.';
    if (!isUsjrEmail(email)) return 'Use an @usjr.edu.ph email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) {
      return HomeScreen(email: _user!.email ?? '');
    }

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _buildAuthForm(colors),
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
          _isCreatingAccount ? 'Create your account' : 'Welcome back',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in with your USJ-R email to continue.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
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
                decoration: const InputDecoration(
                  labelText: 'USJ-R email',
                  hintText: 'name@usjr.edu.ph',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: _isCreatingAccount
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: [
                  _isCreatingAccount
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
                  if (_isCreatingAccount && value.length < 8) {
                    return 'Use at least 8 characters.';
                  }
                  return null;
                },
              ),
              if (_isCreatingAccount) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
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
                  onFieldSubmitted: (_) =>
                      widget.supabaseConfigured ? _submit() : null,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _Notice(
                  icon: Icons.error_outline,
                  message: _errorMessage!,
                  isError: true,
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                _Notice(
                  icon: Icons.mark_email_read_outlined,
                  message: _successMessage!,
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: widget.supabaseConfigured && !_isLoading
                    ? _submit
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isCreatingAccount ? 'Create account' : 'Log in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isCreatingAccount = !_isCreatingAccount;
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                child: Text(
                  _isCreatingAccount
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

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: isError ? colors.error : null),
            ),
          ),
        ],
      ),
    );
  }
}
