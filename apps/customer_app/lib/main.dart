import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';

import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize(
    supabaseUrl: 'https://qxwjtbhyywwpcehwhegz.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4d2p0Ymh5eXd3cGNlaHdoZWd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2Mjk3MjAsImV4cCI6MjA4MzIwNTcyMH0.kq3H9IVupqzllFLCHu5ZHC0RvLp0ctMuyThftL8_G0c',
  );

  runApp(
    const ProviderScope(
      child: MilkCustomerApp(),
    ),
  );
}

class MilkCustomerApp extends StatelessWidget {
  const MilkCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Milk Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
