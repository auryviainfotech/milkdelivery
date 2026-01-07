import 'package:flutter/material.dart';
import 'package:milk_core/milk_core.dart';
// import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio; 

/// Reports Screen with Excel export
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'daily';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today),
            label: Text(_dateRange != null 
                ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                : 'Select Date Range'),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download),
            label: const Text('Export Excel'),
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
                  child: _buildReportContent(),
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

  Widget _buildReportContent() {
    switch (_selectedReport) {
      case 'daily':
        return _buildDailySummary();
      case 'revenue':
        return _buildRevenueReport();
      case 'subscription':
        return _buildSubscriptionReport();
      case 'delivery':
        return _buildDeliveryReport();
      case 'customer':
        return _buildCustomerReport();
      default:
        return const Center(child: Text('Select a report'));
    }
  }

  Widget _buildDailySummary() {
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
              _buildMetricCard('Orders Delivered', '156', Icons.check_circle, AppTheme.successColor),
              _buildMetricCard('Pending Orders', '12', Icons.pending, AppTheme.warningColor),
              _buildMetricCard('Failed Deliveries', '3', Icons.error, AppTheme.errorColor),
              _buildMetricCard('Revenue', '₹4,680', Icons.currency_rupee, Colors.purple),
              _buildMetricCard('New Customers', '8', Icons.person_add, Colors.blue),
              _buildMetricCard('Wallet Recharges', '₹12,500', Icons.account_balance_wallet, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueReport() {
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
                Icon(Icons.bar_chart, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Revenue chart will be displayed here', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Total Revenue: ₹2,45,890', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscription Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard('Total Subscriptions', '892', Icons.subscriptions, Colors.blue),
            _buildMetricCard('Active', '756', Icons.check_circle, AppTheme.successColor),
            _buildMetricCard('Paused', '89', Icons.pause_circle, AppTheme.warningColor),
            _buildMetricCard('Expired', '47', Icons.cancel, AppTheme.errorColor),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard('Total Deliveries', '4,523', Icons.local_shipping, Colors.blue),
            _buildMetricCard('Success Rate', '98.2%', Icons.trending_up, AppTheme.successColor),
            _buildMetricCard('Avg Time', '12 min', Icons.timer, Colors.orange),
            _buildMetricCard('Active Drivers', '15', Icons.directions_bike, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard('Total Customers', '1,247', Icons.people, Colors.blue),
            _buildMetricCard('Active', '1,102', Icons.person, AppTheme.successColor),
            _buildMetricCard('New This Month', '89', Icons.person_add, Colors.orange),
            _buildMetricCard('Avg Wallet Balance', '₹340', Icons.account_balance_wallet, Colors.purple),
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
                color: color.withValues(alpha: 0.1),
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
    return '${date.day}/${date.month}/${date.year}';
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

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting report to Excel...'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
    // TODO: Implement actual Excel export using syncfusion_flutter_xlsio
  }
}
