import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';

/// Screen to collect delivery person's name after first login
class DeliveryCompleteProfileScreen extends StatefulWidget {
  const DeliveryCompleteProfileScreen({super.key});

  @override
  State<DeliveryCompleteProfileScreen> createState() => _DeliveryCompleteProfileScreenState();
}

class _DeliveryCompleteProfileScreenState extends State<DeliveryCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _vehicleController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('No user found');

      final profile = UserModel(
        id: user.id,
        phone: user.phone ?? '',
        fullName: _nameController.text.trim(),
        address: _vehicleController.text.trim(), // Using address field for vehicle number
        role: UserRole.delivery,
        createdAt: DateTime.now(),
      );

      await UserRepository.saveProfile(profile);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('🚚', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, Delivery Partner!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete your profile to start deliveries',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Enter your name',
                  ),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),

                // Vehicle Number Field (optional)
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number (Optional)',
                    prefixIcon: Icon(Icons.two_wheeler),
                    hintText: 'e.g. DL 01 AB 1234',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your vehicle registration number helps us track deliveries',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 48),

                FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Start Delivering'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
