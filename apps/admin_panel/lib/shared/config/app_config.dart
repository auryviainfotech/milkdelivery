/// Application configuration for admin panel
/// Change these values to customize the admin panel behavior
class AppConfig {
  AppConfig._();

  // ===== Delivery Person Settings =====
  
  /// Maximum number of customers that can be assigned to a single delivery person
  static const int maxCustomersPerDeliveryPerson = 20;

  // ===== Subscription Settings =====
  
  /// Cutoff time for next-day order generation (24-hour format)
  /// Orders placed after this time will be processed for day after tomorrow
  static const int orderCutoffHour = 22; // 10:00 PM
  static const int orderCutoffMinute = 0;
  
  /// Display string for cutoff time
  static String get orderCutoffDisplay {
    final hour = orderCutoffHour > 12 ? orderCutoffHour - 12 : orderCutoffHour;
    final amPm = orderCutoffHour >= 12 ? 'PM' : 'AM';
    final minute = orderCutoffMinute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  // ===== Default Product Values =====
  
  /// Default quantity of liters for new subscriptions
  static const double defaultSubscriptionLiters = 1.0;
  
  /// Default unit for new products
  static const String defaultProductUnit = '500ml';
  
  /// Default price hint for new products
  static const String defaultPriceHint = '26';

  // ===== Phone Settings =====
  
  /// Country code prefix for phone numbers
  static const String phoneCountryCode = '+91';

  // ===== Order Generation Settings =====
  
  /// Days in advance to generate orders for
  static const int orderGenerationDaysAhead = 1;
}
