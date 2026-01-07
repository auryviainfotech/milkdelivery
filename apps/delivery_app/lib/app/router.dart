import 'package:go_router/go_router.dart';

import '../features/splash/screens/delivery_splash_screen.dart';
import '../features/auth/screens/delivery_login_screen.dart';
import '../features/dashboard/screens/delivery_dashboard_screen.dart';
import '../features/route_list/screens/route_list_screen.dart';
import '../features/delivery_confirm/screens/delivery_confirm_screen.dart';
import '../features/qr_scanner/screens/qr_scanner_screen.dart';

/// Delivery App router configuration
final appRouter = GoRouter(
  initialLocation: '/splash',
  // Global redirect to catch invalid paths
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/' || path.toLowerCase() == '/home') {
      return '/dashboard';
    }
    return null; // No redirect needed
  },
  routes: [

    // Splash screen
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const DeliverySplashScreen(),
    ),

    // Auth
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const DeliveryLoginScreen(),
    ),

    // Dashboard
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DeliveryDashboardScreen(),
    ),

    // Today's route list
    GoRoute(
      path: '/routes',
      name: 'routes',
      builder: (context, state) => const RouteListScreen(),
    ),

    // Delivery confirmation
    GoRoute(
      path: '/delivery/:orderId',
      name: 'delivery',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return DeliveryConfirmScreen(orderId: orderId);
      },
    ),

    // QR Scanner
    GoRoute(
      path: '/scan/:orderId',
      name: 'scan',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return QrScannerScreen(orderId: orderId);
      },
    ),
  ],
);
