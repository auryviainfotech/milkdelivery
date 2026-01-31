import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dashboard/screens/delivery_dashboard_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(deliveryProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
        data: (profile) {
          final name = profile?['full_name'] ?? 'Delivery Person';
          final email = profile?['email'] ?? 'No email';
          final phone = profile?['phone'] ?? 'No phone';
          final address = profile?['address'] ?? 'No address';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info Section
              _buildSectionTitle(context, 'Personal Information'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone'),
                      subtitle: Text(phone),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Address'),
                      subtitle: Text(address),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Section
              _buildSectionTitle(context, 'Settings'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      value: false, // TODO: Implement theme provider
                      onChanged: (value) {
                         // Placeholder for theme toggle
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Theme toggle coming soon!')),
                         );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                         // Placeholder
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              FilledButton.icon(
                onPressed: () async {
                  // Logout logic
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('delivery_person_id');
                  await prefs.remove('delivery_person_name');
                  if (context.mounted) context.go('/login');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
              
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'App Version 1.0.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
