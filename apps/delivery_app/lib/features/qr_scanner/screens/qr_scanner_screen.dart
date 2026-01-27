import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:milk_core/milk_core.dart';

/// QR code scanner screen for delivery verification
class QrScannerScreen extends StatefulWidget {
  final String orderId;

  const QrScannerScreen({super.key, required this.orderId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanned = false;
  String? _scannedCustomerId;
  final _litersController = TextEditingController(text: '1.0');

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _litersController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isScanned = true);
    _controller?.stop();

    // Validate QR code
    _validateAndConfirm(code);
  }

  void _validateAndConfirm(String code) {
    // The QR code is the customer's user ID
    _scannedCustomerId = code;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 64,
          ),
          title: const Text('QR Verified!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the liters you delivered:'),
              const SizedBox(height: 16),
              TextField(
                controller: _litersController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Liters Delivered',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.water_drop),
                  suffixText: 'L',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [0.5, 1.0, 1.5, 2.0].map((liters) {
                  return ActionChip(
                    label: Text('$liters L'),
                    onPressed: () {
                      _litersController.text = liters.toString();
                      setDialogState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isScanned = false);
                _controller?.start();
              },
              child: const Text('Scan Again'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmDelivery();
              },
              child: const Text('Confirm & Deduct Liters'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelivery() async {
    final liters = double.tryParse(_litersController.text) ?? 0;
    if (liters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid liters'),
            backgroundColor: Colors.red),
      );
      setState(() => _isScanned = false);
      _controller?.start();
      return;
    }

    try {
      // Get customer's current liters
      final profile = await SupabaseService.client
          .from('profiles')
          .select('liters_remaining, full_name')
          .eq('id', _scannedCustomerId!)
          .single();

      final currentLiters =
          (profile['liters_remaining'] as num?)?.toDouble() ?? 0.0;
      final customerName = profile['full_name'] ?? 'Customer';

      if (currentLiters < liters) {
        if (!mounted) return;

        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Insufficient Balance'),
            content: Text(
                '$customerName only has ${currentLiters.toStringAsFixed(1)}L remaining.\n'
                'You are trying to deliver $liters L.\n\n'
                'Proceed with negative balance (Overdraft)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Allow Overdraft'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          setState(() => _isScanned = false);
          _controller?.start();
          return;
        }
      }

      // Deduct liters from customer's quota
      await SupabaseService.client.from('profiles').update({
        'liters_remaining': currentLiters - liters,
      }).eq('id', _scannedCustomerId!);

      // Update delivery record
      await SupabaseService.client.from('deliveries').update({
        'status': 'delivered',
        'delivered_at': DateTime.now().toIso8601String(),
        'qr_scanned': true,
        'liters_delivered': liters,
      }).eq('order_id', widget.orderId);

      // Update order status
      await SupabaseService.client
          .from('orders')
          .update({'status': 'delivered'}).eq('id', widget.orderId);

      // Get product name from order for notification
      String productName = 'Milk';
      try {
        final orderData = await SupabaseService.client
            .from('orders')
            .select(
                'subscription_id, subscriptions!orders_subscription_id_fkey(product_id, products!subscriptions_product_id_fkey(name))')
            .eq('id', widget.orderId)
            .maybeSingle();

        if (orderData != null) {
          final subscription =
              orderData['subscriptions'] as Map<String, dynamic>?;
          final product = subscription?['products'] as Map<String, dynamic>?;
          productName = product?['name'] ?? 'Milk';
        }
      } catch (_) {
        // Fallback to 'Milk' if product fetch fails
      }

      // Calculate new liters remaining
      final newLitersRemaining = currentLiters - liters;

      // Send notification to customer
      await SupabaseService.client.from('notifications').insert({
        'user_id': _scannedCustomerId,
        'title': '🥛 Delivery Complete!',
        'body':
            '$productName (${liters.toStringAsFixed(1)}L) delivered. You have ${newLitersRemaining.toStringAsFixed(1)}L remaining.',
        'type': 'deliveryUpdate',
        'data': {
          'order_id': widget.orderId,
          'liters_delivered': liters,
          'liters_remaining': newLitersRemaining,
          'product_name': productName,
        },
      });

      if (mounted) {
        context.go('/routes');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                    'Delivered ${liters.toStringAsFixed(1)}L to $customerName!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isScanned = false);
        _controller?.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        title: const Text('Scan QR Code'),
      ),
      body: Stack(
        children: [
          // Camera view
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Scanner frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: -3,
                    left: -3,
                    child: _buildCorner(colorScheme.primary),
                  ),
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Transform.rotate(
                      angle: 1.5708, // 90 degrees
                      child: _buildCorner(colorScheme.primary),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    left: -3,
                    child: Transform.rotate(
                      angle: -1.5708, // -90 degrees
                      child: _buildCorner(colorScheme.primary),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Transform.rotate(
                      angle: 3.14159, // 180 degrees
                      child: _buildCorner(colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Clear center area
          Center(
            child: Container(
              width: 274,
              height: 274,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Point camera at customer\'s QR code',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'QR code is in customer\'s app under Profile',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Flash toggle
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _controller?.toggleTorch(),
                  icon: const Icon(Icons.flash_on),
                  color: Colors.white,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Color color) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
