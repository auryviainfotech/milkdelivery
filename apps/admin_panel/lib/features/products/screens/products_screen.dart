import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:milk_core/milk_core.dart';

/// Products Management Screen
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'Full Cream Milk', 'price': 30.0, 'unit': '500ml', 'active': true},
    {'id': '2', 'name': 'Toned Milk', 'price': 50.0, 'unit': '1L', 'active': true},
    {'id': '3', 'name': 'Buffalo Milk', 'price': 35.0, 'unit': '500ml', 'active': true},
    {'id': '4', 'name': 'Skimmed Milk', 'price': 45.0, 'unit': '1L', 'active': true},
    {'id': '5', 'name': 'Organic Milk', 'price': 60.0, 'unit': '500ml', 'active': true},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: const [
                DataColumn2(label: Text('Product Name'), size: ColumnSize.L),
                DataColumn2(label: Text('Price'), size: ColumnSize.S),
                DataColumn2(label: Text('Unit'), size: ColumnSize.S),
                DataColumn2(label: Text('Status'), size: ColumnSize.S),
                DataColumn2(label: Text('Actions'), size: ColumnSize.M),
              ],
              rows: _products.map((product) {
                return DataRow2(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('🥛', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            product['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text('₹${product['price'].toStringAsFixed(2)}')),
                    DataCell(Text(product['unit'])),
                    DataCell(
                      Chip(
                        label: Text(
                          product['active'] ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: product['active'] ? AppTheme.successColor : AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: (product['active'] 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor).withValues(alpha: 0.1),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _showProductDialog(context, product: product),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () => _toggleStatus(product),
                            icon: Icon(
                              product['active'] ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            tooltip: product['active'] ? 'Deactivate' : 'Activate',
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(product),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final unitController = TextEditingController(text: product?['unit'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 500ml, 1L',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Save to Supabase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEdit ? 'Product updated' : 'Product added')),
              );
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(Map<String, dynamic> product) {
    setState(() {
      product['active'] = !product['active'];
    });
  }

  void _deleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _products.remove(product));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
