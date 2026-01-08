import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// UPI Payment Service for handling PhonePe, Google Pay, and other UPI apps
class UpiPaymentService {
  /// Merchant UPI ID
  static const String merchantUpiId = '6281011139@ptaxis';
  static const String merchantName = 'Milk Delivery';

  /// Generate UPI payment URL
  static String generateUpiUrl({
    required double amount,
    required String transactionId,
    required String transactionNote,
    String? upiApp, // 'gpay', 'phonepe', 'paytm', or null for generic
  }) {
    final String baseUrl = 'upi://pay';
    final params = {
      'pa': merchantUpiId,
      'pn': merchantName,
      'tn': transactionNote,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tr': transactionId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''), // Clean ID
      'mc': '0000', // External Merchant Code
      'mode': '02', // Secure Intent Mode
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  /// Get app-specific UPI URL
  static String getAppSpecificUrl(String genericUrl, String appType) {
    switch (appType) {
      case 'gpay':
        return genericUrl.replaceFirst('upi://', 'tez://upi/');
      case 'phonepe':
        return genericUrl.replaceFirst('upi://', 'phonepe://');
      case 'paytm':
        return genericUrl.replaceFirst('upi://', 'paytmmp://');
      default:
        return genericUrl;
    }
  }

  /// Launch UPI payment
  static Future<bool> initiatePayment({
    required double amount,
    required String transactionId,
    String transactionNote = 'Wallet Recharge',
    String? preferredApp, // 'gpay', 'phonepe', 'paytm', or null
  }) async {
    try {
      final genericUrl = generateUpiUrl(
        amount: amount,
        transactionId: transactionId,
        transactionNote: transactionNote,
      );

      final url = preferredApp != null
          ? getAppSpecificUrl(genericUrl, preferredApp)
          : genericUrl;

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        return launched;
      } else {
        // Fallback for GPay if tez scheme fails
        if (preferredApp == 'gpay') {
          final fallbackUrl = generateUpiUrl(
            amount: amount,
            transactionId: transactionId,
            transactionNote: transactionNote,
          );
          final fallbackUri = Uri.parse(fallbackUrl);
          if (await canLaunchUrl(fallbackUri)) {
            return await launchUrl(
              fallbackUri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
          }
        }
        debugPrint('Could not launch UPI app: $url');
        return false;
      }
    } catch (e) {
      debugPrint('UPI Payment Error: $e');
      return false;
    }
  }

  /// Check if a specific UPI app is installed
  static Future<bool> isAppInstalled(String appType) async {
    try {
      String testUrl;
      switch (appType) {
        case 'gpay':
          testUrl = 'tez://upi/';
          break;
        case 'phonepe':
          testUrl = 'phonepe://';
          break;
        case 'paytm':
          testUrl = 'paytmmp://';
          break;
        default:
          testUrl = 'upi://pay';
      }
      return await canLaunchUrl(Uri.parse(testUrl));
    } catch (e) {
      return false;
    }
  }

  /// Generate unique transaction ID
  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'MILK$timestamp';
  }
}
