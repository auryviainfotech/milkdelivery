import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Provider for delivery persons list
final deliveryPersonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('profiles')
      .select('*')
      .eq('role', 'delivery')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for today's delivery statistics
final todayDeliveryStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  // Get all deliveries completed today
  final response = await SupabaseService.client
      .from('deliveries')
      .select('*, delivery_person_id')
      .eq('status', 'delivered')
      .gte('delivered_at', startOfDay.toIso8601String())
      .lt('delivered_at', endOfDay.toIso8601String());
  
  final deliveries = List<Map<String, dynamic>>.from(response);
  
  // Count deliveries per person
  final Map<String, int> perPersonCount = {};
  for (final d in deliveries) {
    final personId = d['delivery_person_id']?.toString() ?? '';
    perPersonCount[personId] = (perPersonCount[personId] ?? 0) + 1;
  }
  
  return {
    'total': deliveries.length,
    'perPerson': perPersonCount,
  };
});

/// Delivery Persons Management Screen
class DeliveryPersonsScreen extends ConsumerStatefulWidget {
  const DeliveryPersonsScreen({super.key});

  @override
  ConsumerState<DeliveryPersonsScreen> createState() => _DeliveryPersonsScreenState();
}

class _DeliveryPersonsScreenState extends ConsumerState<DeliveryPersonsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deliveryPersonsAsync = ref.watch(deliveryPersonsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Text(
                  'Delivery Persons',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Delivery Person'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage delivery personnel accounts',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Today's Delivery Stats
            _buildTodayStatsCard(context, ref),
            const SizedBox(height: 24),

            // Delivery persons list
            deliveryPersonsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      const Text('Error loading delivery persons'),
                      Text('$e', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(deliveryPersonsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (persons) {
                if (persons.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(Icons.delivery_dining, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No delivery persons yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click the button above to add your first delivery person',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < persons.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        Consumer(
                          builder: (context, ref, _) {
                            final statsAsync = ref.watch(todayDeliveryStatsProvider);
                            final deliveryCount = statsAsync.when(
                              data: (stats) => (stats['perPerson'] as Map<String, int>? ?? {})[persons[i]['id']] ?? 0,
                              loading: () => 0,
                              error: (_, __) => 0,
                            );
                            return _buildPersonTile(context, persons[i], deliveryCount);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonTile(BuildContext context, Map<String, dynamic> person, int todayDeliveries) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              (person['full_name'] ?? 'D')[0].toUpperCase(),
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person['full_name'] ?? 'Unknown',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  person['phone'] ?? 'No phone',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Today's delivery count badge
          if (todayDeliveries > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: colorScheme.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    '$todayDeliveries today',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, person),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () => _confirmDelete(context, person),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Delivery Person'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    helperText: 'Share this password without spaces',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          phoneController.text.length != 10 ||
                          passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields correctly')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final rawPhone = phoneController.text.trim();
                        final formattedPhone = '+91$rawPhone';
                        final authEmail = 'delivery_$rawPhone@milkdelivery.local';
                        final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
                        final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
                        final localStorage = SharedPreferencesLocalStorage(
                          persistSessionKey: 'temp_delivery_creation_session',
                        );
                        await localStorage.initialize();
                        final tempClient = SupabaseClient(
                          supabaseUrl,
                          supabaseAnonKey,
                          authOptions: FlutterAuthClientOptions(
                            localStorage: localStorage,
                            authFlowType: AuthFlowType.implicit,
                          ),
                        );
                        final authResponse = await tempClient.auth.signUp(
                          email: authEmail,
                          password: passwordController.text,
                        );
                        final newUserId = authResponse.user?.id;
                        if (newUserId == null) {
                          throw Exception('Failed to create delivery login');
                        }

                        final signInResponse = await tempClient.auth.signInWithPassword(
                          email: authEmail,
                          password: passwordController.text,
                        );
                        final signedInUserId = signInResponse.user?.id;
                        if (signedInUserId == null) {
                          throw Exception('Failed to sign in delivery account');
                        }

                        // Use ADMIN client to insert profile (RLS allows admin to insert)
                        debugPrint('=== CREATING DELIVERY PERSON ===');
                        debugPrint('Auth User ID: $newUserId');
                        debugPrint('Email: $authEmail');
                        debugPrint('Phone: $formattedPhone');
                        
                        await SupabaseService.client.from('profiles').insert({
                          'id': newUserId,
                          'full_name': nameController.text.trim(),
                          'phone': formattedPhone,
                          'role': 'delivery',
                          'address': passwordController.text,
                          'created_at': DateTime.now().toIso8601String(),
                        });
                        
                        // VERIFICATION: Confirm the profile was actually created
                        final verifyProfile = await SupabaseService.client
                            .from('profiles')
                            .select('id, full_name, role')
                            .eq('id', newUserId)
                            .maybeSingle();
                        
                        if (verifyProfile == null) {
                          throw Exception('Profile creation failed - profile not found after insert. Auth user was created but profile was not.');
                        }
                        
                        debugPrint('Profile verified: ${verifyProfile['full_name']} (${verifyProfile['role']})');
                        debugPrint('=== DELIVERY PERSON CREATED SUCCESSFULLY ===');
                        
                        // Dispose temp client if possible, or just let garbage collector handle it

                        if (context.mounted) {
                          Navigator.pop(context);
                          ref.invalidate(deliveryPersonsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Delivery person "${nameController.text}" added!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      } catch (e) {
                        String errorMessage = 'Error: $e';
                        
                        // Try to extract more details if it's a PostgrestException
                        if (e is PostgrestException) {
                          errorMessage = 'Database Error: ${e.message}\nDetails: ${e.details}\nHint: ${e.hint}';
                        }
                        else if (e is AuthException) {
                           errorMessage = 'Auth Error: ${e.message}';
                        }
                        
                        // Handle duplicate entry (409 Conflict)
                        if (e.toString().contains('409') || e.toString().toLowerCase().contains('duplicate')) {
                           errorMessage = 'User with this phone number already exists!';
                        }
                        
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Error Occurred'),
                              content: SingleChildScrollView(child: Text(errorMessage)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> person) async {
    final nameController = TextEditingController(text: person['full_name']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Delivery Person'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await SupabaseService.client.from('profiles').update({
                  'full_name': nameController.text.trim(),
                }).eq('id', person['id']);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(deliveryPersonsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery person updated!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Delivery Person?'),
        content: Text('Are you sure you want to remove "${person['full_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await SupabaseService.client.from('profiles').delete().eq('id', person['id']);
        ref.invalidate(deliveryPersonsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery person deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildTodayStatsCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statsAsync = ref.watch(todayDeliveryStatsProvider);
    final personsAsync = ref.watch(deliveryPersonsProvider);

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delivery_dining, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Text(
                  "Today's Deliveries",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.onPrimaryContainer),
                  onPressed: () {
                    ref.invalidate(todayDeliveryStatsProvider);
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: TextStyle(color: colorScheme.error)),
              data: (stats) {
                final total = stats['total'] as int;
                final perPerson = stats['perPerson'] as Map<String, int>;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total count
                    Row(
                      children: [
                        Text(
                          '$total',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'deliveries completed today',
                          style: TextStyle(color: colorScheme.onPrimaryContainer.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Per person breakdown
                    if (perPerson.isNotEmpty) ...[
                      Text(
                        'By Delivery Person:',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      personsAsync.when(
                        loading: () => const Text('...'),
                        error: (_, __) => const Text('Error loading names'),
                        data: (persons) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: perPerson.entries.map((entry) {
                              final person = persons.firstWhere(
                                (p) => p['id'] == entry.key,
                                orElse: () => {'full_name': 'Unknown'},
                              );
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: colorScheme.primary,
                                  child: Text(
                                    '${entry.value}',
                                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
                                  ),
                                ),
                                label: Text(person['full_name'] ?? 'Unknown'),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ] else
                      Text(
                        'No deliveries recorded yet today',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
