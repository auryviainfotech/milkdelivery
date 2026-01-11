import 'package:onesignal_flutter/onesignal_flutter.dart';
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
class NotificationService {
  static bool _initialized = false;
  
  /// Initialize OneSignal with app ID
  /// Call this in main.dart before runApp
  static Future<void> initialize({required String oneSignalAppId}) async {
    if (_initialized) return;
    
    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    
    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);
    
    // Enable in-app messages (paused(false) enables them)
    OneSignal.InAppMessages.paused(false);
    
    // Set up notification handlers
    _setupNotificationHandlers();
    
    // Set up in-app message handlers
    _setupInAppMessageHandlers();
    
    _initialized = true;
  }
  
  /// Set up notification click and foreground handlers
  static void _setupNotificationHandlers() {
    // Handle notification opened (user tapped on notification)
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      _handleNotificationClick(data);
    });
    
    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Display the notification
      event.notification.display();
    });
  }
  
  /// Set up in-app message handlers
  static void _setupInAppMessageHandlers() {
    // Handle in-app message click
    OneSignal.InAppMessages.addClickListener((event) {
      final clickName = event.result.actionId;
      print('In-app message clicked: $clickName');
      // Handle navigation based on action ID if needed
    });
    
    // Handle in-app message lifecycle
    OneSignal.InAppMessages.addWillDisplayListener((event) {
      print('In-app message will display: ${event.message.messageId}');
    });
    
    OneSignal.InAppMessages.addDidDisplayListener((event) {
      print('In-app message displayed: ${event.message.messageId}');
    });
    
    OneSignal.InAppMessages.addDidDismissListener((event) {
      print('In-app message dismissed: ${event.message.messageId}');
    });
  }
  
  /// Handle notification click based on type
  static void _handleNotificationClick(Map<String, dynamic>? data) {
    if (data == null) return;
    
    final type = data['type'] as String?;
    final targetId = data['target_id'] as String?;
    
    // Navigation will be handled by the app using a callback or global key
    // For now, we just log the action
    print('Notification clicked: type=$type, targetId=$targetId');
  }
  
  /// Save the OneSignal player ID to user's profile
  /// Call this after user login
  static Future<void> savePlayerId() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    
    try {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId == null) return;
      
      await SupabaseService.client
          .from('profiles')
          .update({'onesignal_player_id': playerId})
          .eq('id', user.id);
      
      // Also set external user ID for targeting
      OneSignal.login(user.id);
      
      print('OneSignal player ID saved: $playerId');
    } catch (e) {
      print('Error saving player ID: $e');
    }
  }
  
  /// Remove player ID on logout
  static Future<void> removePlayerId() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('profiles')
            .update({'onesignal_player_id': null})
            .eq('id', user.id);
      }
      OneSignal.logout();
    } catch (e) {
      print('Error removing player ID: $e');
    }
  }
  
  /// Set user tags for targeted marketing
  /// Tags can include: subscription_plan, favorite_products, location, etc.
  static void setUserTags(Map<String, String> tags) {
    OneSignal.User.addTags(tags);
  }
  
  /// Remove specific user tags
  static void removeUserTags(List<String> keys) {
    OneSignal.User.removeTags(keys);
  }
  
  /// Check if notifications are enabled
  static bool get areNotificationsEnabled {
    return OneSignal.Notifications.permission;
  }
  
  /// Request notification permission
  static Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }
  
  /// Pause or resume in-app messages
  /// Useful during checkout or important flows
  static void setInAppMessagesPaused(bool paused) {
    OneSignal.InAppMessages.paused(paused);
  }
  
  /// Trigger an in-app message by key
  /// Use this for custom triggers (e.g., "show_offer", "first_purchase")
  static void addInAppMessageTrigger(String key, String value) {
    OneSignal.InAppMessages.addTrigger(key, value);
  }
  
  /// Remove an in-app message trigger
  static void removeInAppMessageTrigger(String key) {
    OneSignal.InAppMessages.removeTrigger(key);
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
