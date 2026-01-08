import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milk_core/milk_core.dart';

/// Offline service for caching deliveries and syncing when online
class OfflineService {
  static const String _deliveriesBoxName = 'cached_deliveries';
  static const String _pendingSyncsBoxName = 'pending_syncs';
  
  static Box? _deliveriesBox;
  static Box? _pendingSyncsBox;
  
  /// Initialize Hive for offline storage
  static Future<void> init() async {
    await Hive.initFlutter();
    _deliveriesBox = await Hive.openBox(_deliveriesBoxName);
    _pendingSyncsBox = await Hive.openBox(_pendingSyncsBoxName);
  }
  
  /// Cache deliveries locally
  static Future<void> cacheDeliveries(List<Map<String, dynamic>> deliveries) async {
    await _deliveriesBox?.clear();
    for (var i = 0; i < deliveries.length; i++) {
      await _deliveriesBox?.put(i.toString(), jsonEncode(deliveries[i]));
    }
    debugPrint('Cached ${deliveries.length} deliveries offline');
  }
  
  /// Get cached deliveries
  static List<Map<String, dynamic>> getCachedDeliveries() {
    if (_deliveriesBox == null) return [];
    
    final List<Map<String, dynamic>> deliveries = [];
    for (var key in _deliveriesBox!.keys) {
      final value = _deliveriesBox!.get(key);
      if (value != null) {
        deliveries.add(jsonDecode(value));
      }
    }
    return deliveries;
  }
  
  /// Queue a delivery status update for syncing later
  static Future<void> queueDeliveryUpdate({
    required String deliveryId,
    required String status,
    String? issueNotes,
  }) async {
    final update = {
      'deliveryId': deliveryId,
      'status': status,
      'issueNotes': issueNotes,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _pendingSyncsBox?.add(jsonEncode(update));
    debugPrint('Queued delivery update for offline sync: $deliveryId');
  }
  
  /// Check if there are pending syncs
  static bool hasPendingSyncs() {
    return (_pendingSyncsBox?.length ?? 0) > 0;
  }
  
  /// Get count of pending syncs
  static int getPendingSyncCount() {
    return _pendingSyncsBox?.length ?? 0;
  }
  
  /// Sync pending updates to server
  static Future<int> syncPendingUpdates() async {
    if (_pendingSyncsBox == null || _pendingSyncsBox!.isEmpty) return 0;
    
    int synced = 0;
    final keysToDelete = <dynamic>[];
    
    for (var key in _pendingSyncsBox!.keys) {
      final value = _pendingSyncsBox!.get(key);
      if (value == null) continue;
      
      try {
        final update = jsonDecode(value);
        
        await SupabaseService.client
            .from('deliveries')
            .update({
              'status': update['status'],
              'issue_notes': update['issueNotes'],
              'delivered_at': update['status'] == 'delivered' 
                  ? DateTime.now().toIso8601String() 
                  : null,
            })
            .eq('id', update['deliveryId']);
        
        keysToDelete.add(key);
        synced++;
        debugPrint('Synced delivery update: ${update['deliveryId']}');
      } catch (e) {
        debugPrint('Failed to sync update: $e');
      }
    }
    
    // Remove synced items
    for (var key in keysToDelete) {
      await _pendingSyncsBox!.delete(key);
    }
    
    return synced;
  }
  
  /// Clear all cached data
  static Future<void> clearCache() async {
    await _deliveriesBox?.clear();
    await _pendingSyncsBox?.clear();
  }
}
