import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milk_core/milk_core.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;

/// Provider for report data from Supabase
final reportDataProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, reportType) async {
  switch (reportType) {
    case 'daily':
      return await _fetchDailyReport();
    case 'revenue':
      return await _fetchRevenueReport();
    case 'subscription':
      return await _fetchSubscriptionReport();
    case 'delivery':
      return await _fetchDeliveryReport();
    case 'customer':
      return await _fetchCustomerReport();
    default:
      return {};
  }
});

Future<Map<String, dynamic>> _fetchDailyReport() async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  final deliveries = await SupabaseService.client
      .from('deliveries')
      .select('status')
      .eq('scheduled_date', today);
  
  final delivered = (deliveries as List).where((d) => d['status'] == 'delivered').length;
  final pending = (deliveries as List).where((d) => d['status'] == 'pending').length;
  final issues = (deliveries as List).where((d) => d['status'] == 'issue').length;
  
  final todaySubscriptions = await SupabaseService.client
      .from('subscriptions')
      .select('total_amount')
      .gte('created_at', '${today}T00:00:00')
      .lte('created_at', '${today}T23:59:59');
  
  final todayRevenue = (todaySubscriptions as List)
      .fold<double>(0, (sum, s) => sum + ((s['total_amount'] as num?)?.toDouble() ?? 0));
  
  final newCustomers = await SupabaseService.client
      .from('profiles')
      .select('id')
      .eq('role', 'customer')
      .gte('created_at', '${today}T00:00:00');
  
  final walletRecharges = await SupabaseService.client
      .from('wallet_transactions')
      .select('amount')
      .eq('type', 'credit')
      .gte('created_at', '${today}T00:00:00');
  
  final totalRecharges = (walletRecharges as List)
      .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
  
  return {
    'delivered': delivered,
    'pending': pending,
    'issues': issues,
    'revenue': todayRevenue,
    'newCustomers': (newCustomers as List).length,
    'walletRecharges': totalRecharges,
  };
}

Future<Map<String, dynamic>> _fetchRevenueReport() async {
  final subscriptions = await SupabaseService.client
      .from('subscriptions')
      .select('total_amount, created_at');
  
  final totalRevenue = (subscriptions as List)
      .fold<double>(0, (sum, s) => sum + ((s['total_amount'] as num?)?.toDouble() ?? 0));
  
  return {'totalRevenue': totalRevenue, 'subscriptions': subscriptions};
}

Future<Map<String, dynamic>> _fetchSubscriptionReport() async {
  final subscriptions = await SupabaseService.client
      .from('subscriptions')
      .select('status');
  
  final total = (subscriptions as List).length;
  final active = (subscriptions as List).where((s) => s['status'] == 'active').length;
  final paused = (subscriptions as List).where((s) => s['status'] == 'paused').length;
  final expired = (subscriptions as List).where((s) => s['status'] == 'expired').length;
  
  return {'total': total, 'active': active, 'paused': paused, 'expired': expired};
}

Future<Map<String, dynamic>> _fetchDeliveryReport() async {
  final deliveries = await SupabaseService.client
      .from('deliveries')
      .select('status');
  
  final total = (deliveries as List).length;
  final delivered = (deliveries as List).where((d) => d['status'] == 'delivered').length;
  final successRate = total > 0 ? (delivered / total * 100) : 0;
  
  final drivers = await SupabaseService.client
      .from('profiles')
      .select('id')
      .eq('role', 'delivery');
  
  return {
    'total': total,
    'delivered': delivered,
    'successRate': successRate.toStringAsFixed(1),
    'activeDrivers': (drivers as List).length,
  };
}

Future<Map<String, dynamic>> _fetchCustomerReport() async {
  final customers = await SupabaseService.client
      .from('profiles')
      .select('id, created_at')
      .eq('role', 'customer');
  
  final total = (customers as List).length;
  
  final thisMonth = DateTime.now().month;
  final thisYear = DateTime.now().year;
  final newThisMonth = (customers as List).where((c) {
    if (c['created_at'] == null) return false;
    final created = DateTime.parse(c['created_at']);
    return created.month == thisMonth && created.year == thisYear;
  }).length;
  
  final wallets = await SupabaseService.client
      .from('wallets')
      .select('balance');
  
  final avgBalance = (wallets as List).isEmpty ? 0 :
      (wallets as List).fold<double>(0, (sum, w) => sum + ((w['balance'] as num?)?.toDouble() ?? 0)) / (wallets as List).length;
  
  final activeCustomers = await SupabaseService.client
      .from('subscriptions')
      .select('user_id')
      .eq('status', 'active');
  
  return {
    'total': total,
    'active': (activeCustomers as List).toSet().length,
    'newThisMonth': newThisMonth,
    'avgBalance': avgBalance.toStringAsFixed(0),
  };
}

/// Reports Screen with Real Data and CSV Export
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedReport = 'daily';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDataProvider(_selectedReport));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(reportDataProvider(_selectedReport));
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today),
            label: Text(_dateRange != null 
                ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                : 'Select Date Range'),
          ),
          const SizedBox(width: 16),
          IconButton.filled(
            onPressed: () => _exportToCSV(reportAsync),
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report type tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildReportTab('Daily Summary', 'daily', Icons.today),
                  const SizedBox(width: 12),
                  _buildReportTab('Revenue Report', 'revenue', Icons.currency_rupee),
                  const SizedBox(width: 12),
                  _buildReportTab('Subscription Report', 'subscription', Icons.subscriptions),
                  const SizedBox(width: 12),
                  _buildReportTab('Delivery Report', 'delivery', Icons.local_shipping),
                  const SizedBox(width: 12),
                  _buildReportTab('Customer Report', 'customer', Icons.people),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report content
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: reportAsync.when(
                    data: (data) => _buildReportContent(data),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab(String label, String value, IconData icon) {
    final isSelected = _selectedReport == value;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => setState(() => _selectedReport = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> data) {
    switch (_selectedReport) {
      case 'daily':
        return _buildDailySummary(data);
      case 'revenue':
        return _buildRevenueReport(data);
      case 'subscription':
        return _buildSubscriptionReport(data);
      case 'delivery':
        return _buildDeliveryReport(data);
      case 'customer':
        return _buildCustomerReport(data);
      default:
        return const Center(child: Text('Select a report'));
    }
  }

  Widget _buildDailySummary(Map<String, dynamic> data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Summary - ${_formatDate(DateTime.now())}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard('Orders Delivered', '${data['delivered'] ?? 0}', Icons.check_circle, AppTheme.successColor),
              _buildMetricCard('Pending Orders', '${data['pending'] ?? 0}', Icons.pending, AppTheme.warningColor),
              _buildMetricCard('Failed Deliveries', '${data['issues'] ?? 0}', Icons.error, AppTheme.errorColor),
              _buildMetricCard('Revenue', '₹${(data['revenue'] ?? 0).toStringAsFixed(0)}', Icons.currency_rupee, Colors.purple),
              _buildMetricCard('New Customers', '${data['newCustomers'] ?? 0}', Icons.person_add, Colors.blue),
              _buildMetricCard('Wallet Recharges', '₹${(data['walletRecharges'] ?? 0).toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueReport(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Revenue Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Total Revenue from Subscriptions', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('₹${(data['totalRevenue'] ?? 0).toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionReport(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscription Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard('Total Subscriptions', '${data['total'] ?? 0}', Icons.subscriptions, Colors.blue),
            _buildMetricCard('Active', '${data['active'] ?? 0}', Icons.check_circle, AppTheme.successColor),
            _buildMetricCard('Paused', '${data['paused'] ?? 0}', Icons.pause_circle, AppTheme.warningColor),
            _buildMetricCard('Expired', '${data['expired'] ?? 0}', Icons.cancel, AppTheme.errorColor),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryReport(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard('Total Deliveries', '${data['total'] ?? 0}', Icons.local_shipping, Colors.blue),
            _buildMetricCard('Success Rate', '${data['successRate'] ?? 0}%', Icons.trending_up, AppTheme.successColor),
            _buildMetricCard('Delivered', '${data['delivered'] ?? 0}', Icons.check_circle, Colors.green),
            _buildMetricCard('Active Drivers', '${data['activeDrivers'] ?? 0}', Icons.directions_bike, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerReport(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard('Total Customers', '${data['total'] ?? 0}', Icons.people, Colors.blue),
            _buildMetricCard('Active', '${data['active'] ?? 0}', Icons.person, AppTheme.successColor),
            _buildMetricCard('New This Month', '${data['newThisMonth'] ?? 0}', Icons.person_add, Colors.orange),
            _buildMetricCard('Avg Wallet Balance', '₹${data['avgBalance'] ?? 0}', Icons.account_balance_wallet, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  void _exportToCSV(AsyncValue<Map<String, dynamic>> reportAsync) {
    reportAsync.whenData((data) {
      final csvContent = StringBuffer();
      
      // Add report header
      csvContent.writeln('${_selectedReport.toUpperCase()} REPORT');
      csvContent.writeln('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      csvContent.writeln('');
      
      // Add data based on report type
      data.forEach((key, value) {
        if (key != 'subscriptions') {
          csvContent.writeln('$key,$value');
        }
      });
      
      // Create and download file
      final bytes = utf8.encode(csvContent.toString());
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${_selectedReport}_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report exported successfully!')),
      );
    });
  }
}
