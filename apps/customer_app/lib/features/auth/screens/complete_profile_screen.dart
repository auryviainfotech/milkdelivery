import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';

/// Screen to collect user name and general area after first login
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
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
        address: _areaController.text.trim(), // Storing area in address for now
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      await UserRepository.saveProfile(profile);
      await WalletRepository.createWallet(user.id);

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
                Text(
                  'Welcome to Milk Delivery! 🥛',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us a bit about yourself to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Enter your name',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),

                // Area/Society Field
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area / Society',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    hintText: 'e.g. Sector 45 or Palm Heights',
                  ),
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter your area' : null,
                ),
                const SizedBox(height: 4),
                const Text(
                  'We will ask for your full door-to-door address when you place your first order.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 48),

                FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Get Started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
