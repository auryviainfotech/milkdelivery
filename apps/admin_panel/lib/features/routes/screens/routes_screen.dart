import 'package:flutter/material.dart';
import 'package:milk_core/milk_core.dart';

/// Routes Generation Screen
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isGenerating = false;

  final List<Map<String, dynamic>> _routes = [
    {'id': '1', 'driver': 'Ramesh Kumar', 'phone': '+91 98765 43210', 'orders': 25, 'status': 'pending', 'area': 'Green Park, Hauz Khas'},
    {'id': '2', 'driver': 'Suresh Singh', 'phone': '+91 87654 32109', 'orders': 28, 'status': 'in_progress', 'area': 'Vasant Kunj, Vasant Vihar'},
    {'id': '3', 'driver': 'Mohan Sharma', 'phone': '+91 76543 21098', 'orders': 22, 'status': 'completed', 'area': 'Lajpat Nagar, Greater Kailash'},
  ];

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Routes'),
        actions: [
          OutlinedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_formatDate(_selectedDate)),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateRoutes,
            icon: _isGenerating 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.route),
            label: Text(_isGenerating ? 'Generating...' : 'Generate Routes'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    context,
                    icon: Icons.shopping_bag,
                    label: 'Total Orders',
                    value: '75',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatsCard(
                    context,
                    icon: Icons.people,
                    label: 'Drivers Available',
                    value: '3',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatsCard(
                    context,
                    icon: Icons.timer,
                    label: 'Estimated Time',
                    value: '4-5 hrs',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Routes list
            Text(
              'Driver Routes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final route = _routes[index];
                  return _buildRouteCard(route);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color statusColor;
    String statusText;
    switch (route['status']) {
      case 'pending':
        statusColor = AppTheme.pendingColor;
        statusText = 'Pending';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = AppTheme.successColor;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Driver avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                route['driver'].substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Driver info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route['driver'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        route['phone'],
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          route['area'],
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Orders count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${route['orders']} orders',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Actions
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'View Route',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Route',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _generateRoutes() async {
    setState(() => _isGenerating = true);
    
    // Simulate route generation
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routes generated successfully!')),
      );
    }
  }
}
