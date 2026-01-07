import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/complete_profile_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/wallet/screens/wallet_screen.dart';
import '../features/subscription/screens/subscription_list_screen.dart';
import '../features/subscription/screens/subscription_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../shared/widgets/main_shell.dart';

/// App router configuration using GoRouter
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
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      name: 'otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/complete-profile',
      name: 'completeProfile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),

    // Main app shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Nested routes
    GoRoute(
      path: '/wallet',
      name: 'wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/subscriptions',
      name: 'subscriptions',
      builder: (context, state) => const SubscriptionListScreen(),
    ),
    GoRoute(
      path: '/subscription/:id',
      name: 'subscriptionDetail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SubscriptionDetailScreen(subscriptionId: id);
      },
    ),
    GoRoute(
      path: '/order/:id',
      name: 'orderDetail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return OrderDetailScreen(orderId: id);
      },
    ),
  ],
);
