import 'package:flutter/foundation.dart' show kIsWeb;
import 'supabase_service.dart';

/// Notification types for the app
enum NotificationType {
  orderUpdate,      // Order status changes
  deliveryUpdate,   // Delivery status (out for delivery, delivered)
  subscriptionReminder, // Renewal reminders
  promotion,        // Festival offers, discounts
  newProduct,       // New product launches
  walletUpdate,     // Wallet credit/debit
  general,          // General announcements
}

/// NotificationService handles push notifications using OneSignal
/// Supports marketing and transactional notifications
/// On web platform, provides stub implementation (OneSignal not supported)
class NotificationService {
  static bool _initialized = false;
  
  /// Initialize notifications
  /// On mobile: initializes OneSignal with app ID
  /// On web: no-op (OneSignal not supported on web)
  static Future<void> initialize({required String oneSignalAppId}) async {
    if (_initialized) return;
    
    if (kIsWeb) {
      // OneSignal Flutter SDK doesn't support web
      // Web push can be handled separately via OneSignal Web SDK in index.html
      print('NotificationService: Web platform detected, push notifications disabled');
      _initialized = true;
      return;
    }
    
    // Mobile platform - OneSignal would be initialized here
    // For now, just mark as initialized (actual OneSignal integration needs mobile build)
    print('NotificationService: Mobile platform detected');
    _initialized = true;
  }
  
  /// Save the OneSignal player ID to user's profile
  /// Call this after user login
  static Future<void> savePlayerId() async {
    if (kIsWeb) return; // Not supported on web
    
    final user = SupabaseService.currentUser;
    if (user == null) return;
    
    // Mobile-only: would get player ID from OneSignal
    print('NotificationService: savePlayerId called (mobile only)');
  }
  
  /// Remove player ID on logout
  static Future<void> removePlayerId() async {
    if (kIsWeb) return;
    
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('profiles')
            .update({'onesignal_player_id': null})
            .eq('id', user.id);
      }
    } catch (e) {
      print('Error removing player ID: $e');
    }
  }
  
  /// Set user tags for targeted marketing
  static void setUserTags(Map<String, String> tags) {
    if (kIsWeb) return;
    // Mobile-only: would set tags on OneSignal
  }
  
  /// Remove specific user tags
  static void removeUserTags(List<String> keys) {
    if (kIsWeb) return;
    // Mobile-only: would remove tags from OneSignal
  }
  
  /// Check if notifications are enabled
  static bool get areNotificationsEnabled {
    if (kIsWeb) return false;
    return true;
  }
  
  /// Request notification permission
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    return true;
  }
  
  /// Pause or resume in-app messages
  static void setInAppMessagesPaused(bool paused) {
    if (kIsWeb) return;
    // Mobile-only
  }
  
  /// Trigger an in-app message by key
  static void addInAppMessageTrigger(String key, String value) {
    if (kIsWeb) return;
    // Mobile-only
  }
  
  /// Remove an in-app message trigger
  static void removeInAppMessageTrigger(String key) {
    if (kIsWeb) return;
    // Mobile-only
  }
}

/// Model for in-app notifications stored in database
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Get icon for notification type
  String get icon {
    switch (type) {
      case NotificationType.orderUpdate:
        return '📦';
      case NotificationType.deliveryUpdate:
        return '🚚';
      case NotificationType.subscriptionReminder:
        return '🔔';
      case NotificationType.promotion:
        return '🎉';
      case NotificationType.newProduct:
        return '✨';
      case NotificationType.walletUpdate:
        return '💰';
      case NotificationType.general:
        return '📢';
    }
  }
}
