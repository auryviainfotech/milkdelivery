import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../shared/providers/auth_providers.dart';
import 'package:milk_core/milk_core.dart';

/// Full screen QR code display for delivery confirmation
class QrCodeScreen extends ConsumerStatefulWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  double _previousBrightness = 0.5;

  @override
  void initState() {
    super.initState();
    _increaseBrightness();
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _increaseBrightness() async {
    // Note: Screen brightness control would require platform-specific implementation
    // For now, we'll just show a white background to make scanning easier
  }

  Future<void> _restoreBrightness() async {
    // Restore brightness when leaving
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('My QR Code'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => _buildContent(context, profile),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Error loading QR code', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel? profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (profile == null || profile.qrCode == null || profile.qrCode!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 80, color: colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              'QR Code Not Available',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your QR code will be generated automatically. Please try again later.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // User info
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              (profile.fullName ?? 'U')[0].toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName ?? 'Customer',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            profile.phone,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 32),

          // QR Code Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                // QR Code
                QrImageView(
                  data: profile.qrCode!,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.roundedRect,
                    color: colorScheme.primary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.roundedRect,
                    color: Colors.black87,
                  ),
                  errorStateBuilder: (ctx, err) => const Center(
                    child: Text('Error generating QR'),
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Value
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        profile.qrCode!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'How to use',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Show this QR code to the delivery person when they arrive. They will scan it to confirm your milk delivery.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Copy button
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: profile.qrCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check, color: Colors.white),
                      SizedBox(width: 8),
                      Text('QR code copied to clipboard'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Code'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
