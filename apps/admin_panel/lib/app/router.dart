import 'package:go_router/go_router.dart';

import '../features/auth/screens/admin_login_screen.dart';
import '../features/dashboard/screens/admin_dashboard_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/customers/screens/customers_screen.dart';
import '../features/delivery_persons/screens/delivery_persons_screen.dart';
import '../features/subscriptions/screens/subscriptions_screen.dart';
import '../features/wallets/screens/wallets_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/routes/screens/routes_screen.dart';
import '../shared/widgets/admin_shell.dart';

final adminRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Redirect root and home to dashboard
    GoRoute(
      path: '/',
      redirect: (_, __) => '/dashboard',
    ),
    GoRoute(
      path: '/home',
      redirect: (_, __) => '/dashboard',
    ),

    // Auth route
    GoRoute(
      path: '/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    
    // Main shell with sidebar navigation
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          builder: (context, state) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/customers',
          name: 'customers',
          builder: (context, state) => const CustomersScreen(),
        ),
        GoRoute(
          path: '/delivery-persons',
          name: 'deliveryPersons',
          builder: (context, state) => const DeliveryPersonsScreen(),
        ),
        GoRoute(
          path: '/subscriptions',
          name: 'subscriptions',
          builder: (context, state) => const SubscriptionsScreen(),
        ),
        GoRoute(
          path: '/wallets',
          name: 'wallets',
          builder: (context, state) => const WalletsScreen(),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/routes',
          name: 'routes',
          builder: (context, state) => const RoutesScreen(),
        ),
      ],
    ),
  ],
);
