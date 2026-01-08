import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Razorpay Payment Service for handling UPI, Cards, and other payments
class RazorpayService {
  /// Razorpay Key ID loaded from .env file
  static String get keyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  
  static Razorpay? _razorpay;
  static Function(PaymentSuccessResponse)? _onSuccess;
  static Function(PaymentFailureResponse)? _onError;
  static Function(ExternalWalletResponse)? _onExternalWallet;

  /// Initialize Razorpay with callbacks
  static void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  static void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  static void _handleError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _onError?.call(response);
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  /// Open Razorpay checkout
  static void openCheckout({
    required double amount,
    required String orderId,
    required String description,
    String? email,
    String? phone,
    String? name,
  }) {
    if (_razorpay == null) {
      debugPrint('Razorpay not initialized! Call init() first.');
      return;
    }

    var options = {
      'key': keyId,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Milk Delivery',
      'description': description,
      'prefill': {
        'contact': phone ?? '',
        'email': email ?? 'customer@milkdelivery.com',
        'name': name ?? '',
      },
      'theme': {
        'color': '#1E88E5',
      },
      'notes': {
        'order_id': orderId,
      },
      // Enable all payment methods
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  /// Dispose Razorpay instance
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _onSuccess = null;
    _onError = null;
    _onExternalWallet = null;
  }

  /// Check if Razorpay is initialized
  static bool get isInitialized => _razorpay != null;
}
