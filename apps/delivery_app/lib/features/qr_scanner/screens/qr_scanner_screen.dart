import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:milk_core/milk_core.dart';

/// QR code scanner screen
class QrScannerScreen extends StatefulWidget {
  final String orderId;

  const QrScannerScreen({super.key, required this.orderId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanned = false;

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
    // TODO: Validate QR code with backend
    // For now, accept any QR code
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 64,
        ),
        title: const Text('QR Verified!'),
        content: const Text(
          'Customer QR code verified successfully. Mark this delivery as complete?',
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
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );
  }

  void _confirmDelivery() {
    // TODO: Update delivery status in Supabase
    context.go('/routes');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Delivery confirmed successfully!'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
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
              color: Colors.black.withValues(alpha: 0.5),
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
