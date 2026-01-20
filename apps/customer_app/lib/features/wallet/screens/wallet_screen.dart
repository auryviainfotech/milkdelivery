import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Provider for quota data
final quotaDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  
  final response = await SupabaseService.client
      .from('profiles')
      .select('liters_remaining, subscription_status, full_name')
      .eq('id', user.id)
      .maybeSingle();
  return response;
});

/// Liters Quota Screen - Shows remaining liters and QR code for delivery verification
/// This screen replaces the old Wallet screen
class LitersQuotaScreen extends ConsumerWidget {
  const LitersQuotaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = SupabaseService.currentUser;
    final quotaAsync = ref.watch(quotaDataProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(quotaDataProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: const Text('My Quota'),
              centerTitle: true,
            ),
            
            SliverToBoxAdapter(
              child: quotaAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (data) {
                  final litersRemaining = (data?['liters_remaining'] as num?)?.toDouble() ?? 0.0;
                  final subscriptionStatus = data?['subscription_status'] as String? ?? 'inactive';
                  final qrCode = user?.id ?? 'NO_USER';
                  
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Liters Display Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1E88E5),
                                const Color(0xFF1565C0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E88E5).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Liters Remaining',
                                    style: TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    litersRemaining.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 10, left: 4),
                                    child: Text(
                                      'L',
                                      style: TextStyle(color: Colors.white70, fontSize: 28),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStatusBadge(subscriptionStatus),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // QR Code Section
                        Text(
                          'Your Delivery QR Code',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Show this to the delivery person to verify your delivery',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // QR Code Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: QrImageView(
                                  data: qrCode,
                                  version: QrVersions.auto,
                                  size: 180,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF1565C0),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tag, size: 16, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      qrCode.length > 8 ? qrCode.substring(0, 8).toUpperCase() : qrCode,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // How it works section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'How it works',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStep('1', 'Admin adds liters to your account after payment', Colors.blue.shade700),
                              _buildStep('2', 'Delivery person scans your QR code', Colors.blue.shade700),
                              _buildStep('3', 'Liters are deducted from your quota', Colors.blue.shade700),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'active':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.greenAccent;
        label = 'Active Subscription';
        icon = Icons.check_circle;
        break;
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orangeAccent;
        label = 'Pending Approval';
        icon = Icons.hourglass_top;
        break;
      default:
        bgColor = Colors.white.withOpacity(0.15);
        textColor = Colors.white70;
        label = 'No Active Subscription';
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: TextStyle(color: color, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
