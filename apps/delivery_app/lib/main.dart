import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/router.dart';
import 'services/offline_service.dart';
import 'app/providers/theme_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Validate required environment variables
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl == null || supabaseUrl.isEmpty ||
        supabaseKey == null || supabaseKey.isEmpty) {
      throw Exception('Missing Supabase configuration. Check .env file.');
    }

    // Initialize Supabase from environment
    await SupabaseService.initialize(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseKey,
    );

    // Initialize offline storage
    await OfflineService.init();
    
    // Sync any pending offline updates on app start
    if (OfflineService.hasPendingSyncs()) {
      final synced = await OfflineService.syncPendingUpdates();
      if (kDebugMode && synced > 0) {
        debugPrint('Synced $synced pending updates');
      }
    }

    runApp(
      const ProviderScope(
        child: MilkDeliveryApp(),
      ),
    );
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('FATAL ERROR IN MAIN: $e');
      debugPrint(stack.toString());
    }
    // Fallback UI in case of crash
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to start app:\n$e', 
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  }
}

class MilkDeliveryApp extends ConsumerWidget {
  const MilkDeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Milk Delivery - Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
