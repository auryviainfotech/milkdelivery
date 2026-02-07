import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milk_core/milk_core.dart';

/// Admin panel sidebar shell for web navigation
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLocation = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationDrawer(
            selectedIndex: _getSelectedIndex(currentLocation),
            onDestinationSelected: (index) => _onDestinationSelected(context, index),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🥛', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Milk Delivery',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
              
              // Navigation items
              const NavigationDrawerDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Products'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Customers'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.delivery_dining_outlined),
                selectedIcon: Icon(Icons.delivery_dining),
                label: Text('Delivery Persons'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.subscriptions_outlined),
                selectedIcon: Icon(Icons.subscriptions),
                label: Text('Subscriptions'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: Text('Deliveries'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.assignment_ind_outlined),
                selectedIcon: Icon(Icons.assignment_ind),
                label: Text('Assignments'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: Text('Shop Orders'),
              ),

              const NavigationDrawerDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Reports'),
              ),
              
              const SizedBox(height: 40),
              const Divider(indent: 16, endIndent: 16),
              
              // Logout
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
          
          // Main content
          Expanded(
            child: Container(
              color: colorScheme.surface,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/delivery-persons')) return 3;
    if (location.startsWith('/subscriptions')) return 4;
    if (location.startsWith('/deliveries')) return 5;
    if (location.startsWith('/assignments')) return 6;
    if (location.startsWith('/shop-orders')) return 7;
    if (location.startsWith('/reports')) return 8;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final routes = [
      '/dashboard',
      '/products',
      '/customers',
      '/delivery-persons',
      '/subscriptions',
      '/deliveries',
      '/assignments',
      '/shop-orders',
      '/reports',
    ];
    context.go(routes[index]);
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.client.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
