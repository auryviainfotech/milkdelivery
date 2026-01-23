import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/screens/delivery_dashboard_screen.dart'; // Import providers

/// Delivery personnel login screen with phone + password
class DeliveryLoginScreen extends ConsumerStatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  ConsumerState<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends ConsumerState<DeliveryLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final rawPhone = _phoneController.text.trim();
      final phone = '+91$rawPhone';
      final password = _passwordController.text;
      final authEmail = 'delivery_$rawPhone@milkdelivery.local';
      
      debugPrint('=== LOGIN ATTEMPT ===');
      debugPrint('Phone: $phone');
      
      final authResponse = await SupabaseService.client.auth.signInWithPassword(
        email: authEmail,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Login failed');
      }

      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('Response: $response');

      if (response == null) {
        await SupabaseService.client.auth.signOut();
        throw Exception('Delivery account not linked');
      }

      final role = response['role'];
      if (role != 'delivery' && role != 'admin') {
        await SupabaseService.client.auth.signOut();
        throw Exception('Access denied');
      }
      
      debugPrint('Found profile: ${response['full_name']}, ID: ${response['id']}');

      // Store the profile ID for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('delivery_person_id', user.id);
      await prefs.setString('delivery_person_name', response['full_name'] ?? 'Delivery Person');
      
      debugPrint('Stored delivery_person_id: ${response['id']}');

      // Force refresh of providers to load new user data
      ref.invalidate(deliveryPersonIdProvider);
      ref.invalidate(deliveryProfileProvider);
      ref.invalidate(todayDeliveriesProvider);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Wrong phone number or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Account not activated. Contact admin.';
    }
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🚚', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Delivery Partner',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to start your deliveries',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Phone number input
                Text(
                  'Mobile Number',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: '9876543210',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇮🇳 +91', style: theme.textTheme.bodyLarge),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 24,
                            color: colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length != 10) {
                      return 'Phone number must be 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password input
                Text(
                  'Password',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Login button
                FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 16),

                // Help text
                Text(
                  'Forgot password? Contact your admin.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
