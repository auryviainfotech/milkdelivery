import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:milk_core/milk_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for products from Supabase
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('products')
      .select('*')
      .order('category')
      .order('name');
  return List<Map<String, dynamic>>.from(response);
});

/// Products Management Screen with Category Support
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _categoryFilter = 'all'; // 'all', 'subscription', 'one_time'

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(productsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _showProductDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category filter chips
            Row(
              children: [
                const Text('Filter by: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('All'),
                  selected: _categoryFilter == 'all',
                  onSelected: (_) => setState(() => _categoryFilter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Text('🥛'),
                  label: const Text('Subscription (Daily Milk)'),
                  selected: _categoryFilter == 'subscription',
                  onSelected: (_) => setState(() => _categoryFilter = 'subscription'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Text('🧈'),
                  label: const Text('One-Time (Butter, Ghee, etc.)'),
                  selected: _categoryFilter == 'one_time',
                  onSelected: (_) => setState(() => _categoryFilter = 'one_time'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Products table
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // Filter by category
                  final filtered = _categoryFilter == 'all'
                      ? products
                      : products.where((p) => p['category'] == _categoryFilter).toList();
                  
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No products found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _showProductDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Product'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 800,
                        columns: const [
                          DataColumn2(label: Text('Product Name'), size: ColumnSize.L),
                          DataColumn2(label: Text('Category'), size: ColumnSize.S),
                          DataColumn2(label: Text('Price'), size: ColumnSize.S),
                          DataColumn2(label: Text('Unit'), size: ColumnSize.S),
                          DataColumn2(label: Text('Status'), size: ColumnSize.S),
                          DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                        ],
                        rows: filtered.map((product) {
                          final isActive = product['is_active'] ?? true;
                          final category = product['category'] ?? 'subscription';
                          final isSubscription = category == 'subscription';
                          
                          return DataRow2(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isSubscription 
                                            ? colorScheme.primaryContainer 
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: product['image_url'] != null 
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                product['image_url'],
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Text(product['emoji'] ?? '🥛', style: const TextStyle(fontSize: 14)),
                                              ),
                                            )
                                          : Text(product['emoji'] ?? '🥛', style: const TextStyle(fontSize: 14)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            product['name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          if (product['description'] != null && product['description'].toString().isNotEmpty)
                                            Text(
                                              product['description'],
                                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSubscription ? Colors.blue.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isSubscription ? 'Subscription' : 'One-Time',
                                    style: TextStyle(
                                      color: isSubscription ? Colors.blue : Colors.orange.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text('₹${(product['price'] ?? 0).toStringAsFixed(2)}')),
                              DataCell(Text(product['unit'] ?? '-')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isActive ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                                        isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      ),
                                      tooltip: isActive ? 'Deactivate' : 'Activate',
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Future<String?> _uploadImage(String fileName, Uint8List bytes) async {
    try {
      final path = 'product_images/$fileName';
      await SupabaseService.client.storage.from('products').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return SupabaseService.client.storage.from('products').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload error: $e');
      // If bucket doesn't exist, this will fail. Ideally handle this gracefully.
      rethrow;
    }
  }

  void _showProductDialog(BuildContext context, {Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descController = TextEditingController(text: product?['description'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final unitController = TextEditingController(text: product?['unit'] ?? '500ml');
    String selectedEmoji = product?['emoji'] ?? '🥛';
    String selectedCategory = product?['category'] ?? 'subscription';
    Uint8List? selectedImageBytes;
    bool isLoading = false;
    String? errorMessage;
    
    // Emojis organized by category
    const subscriptionEmojis = ['🥛', '🫙', '🍼'];  // Milk, Curd, Bottle
    const oneTimeEmojis = ['🧈', '🧀', '🫙', '🍨', '🥤', '🍬', '📦'];  // Butter, Cheese, Ghee, Sweet, Drink, Candy, Package
    
    List<String> getEmojisForCategory(String category) {
      return category == 'subscription' ? subscriptionEmojis : oneTimeEmojis;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentEmojis = getEmojisForCategory(selectedCategory);
          // Reset emoji if switching category and current emoji isn't in new category
          if (!currentEmojis.contains(selectedEmoji)) {
            selectedEmoji = currentEmojis.first;
          }

          Future<void> pickImage() async {
            try {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final bytes = await image.readAsBytes();
                setState(() {
                  selectedImageBytes = bytes;
                });
              }
            } catch (e) {
              setState(() => errorMessage = 'Error picking image: $e');
            }
          }
          
          return AlertDialog(
            title: Text(isEdit ? 'Edit Product' : 'Add Product'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: selectedImageBytes != null
                                ? DecorationImage(image: MemoryImage(selectedImageBytes!), fit: BoxFit.cover)
                                : (product?['image_url'] != null
                                    ? DecorationImage(image: NetworkImage(product!['image_url']), fit: BoxFit.cover)
                                    : null),
                          ),
                          child: selectedImageBytes == null && product?['image_url'] == null
                              ? const Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: TextButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select Image'),
                    )),
                    const SizedBox(height: 16),

                    // Category selector
                    const Text('Product Category *', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Row(
                              children: [
                                Text('🥛 '),
                                Expanded(child: Text('Subscription', style: TextStyle(fontSize: 13))),
                              ],
                            ),
                            subtitle: const Text('Daily milk', style: TextStyle(fontSize: 11)),
                            value: 'subscription',
                            groupValue: selectedCategory,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => selectedCategory = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Row(
                              children: [
                                Text('🧈 '),
                                Expanded(child: Text('One-Time', style: TextStyle(fontSize: 13))),
                              ],
                            ),
                            subtitle: const Text('Butter, Ghee', style: TextStyle(fontSize: 11)),
                            value: 'one_time',
                            groupValue: selectedCategory,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => selectedCategory = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Emoji picker
                    const Text('Product Icon (Fallback):', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentEmojis.map((emoji) => GestureDetector(
                        onTap: () => setState(() => selectedEmoji = emoji),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedEmoji == emoji ? Theme.of(context).colorScheme.primaryContainer : null,
                            border: Border.all(
                              color: selectedEmoji == emoji ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                              width: selectedEmoji == emoji ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Product name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name *',
                        border: const OutlineInputBorder(),
                        hintText: selectedCategory == 'subscription' 
                            ? 'e.g., Nandini Pasteurised Cow Milk (Green)'
                            : 'e.g., Nandini Butter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., Fresh unsalted butter',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Price and Unit
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price (₹) *',
                              border: OutlineInputBorder(),
                              hintText: '26',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: InputDecoration(
                              labelText: 'Unit/Pack Size',
                              border: const OutlineInputBorder(),
                              hintText: '500ml',
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Error message
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isLoading ? null : () async {
                  // Validation
                  if (nameController.text.trim().isEmpty) {
                    setState(() => errorMessage = 'Product name is required');
                    return;
                  }
                  final price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    setState(() => errorMessage = 'Valid price is required');
                    return;
                  }
                  
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  
                  try {
                    String? imageUrl = product?['image_url'];
                    
                    if (selectedImageBytes != null) {
                      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                      imageUrl = await _uploadImage(fileName, selectedImageBytes!);
                    }

                    final data = {
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                      'price': price,
                      'unit': unitController.text.trim().isEmpty ? '500ml' : unitController.text.trim(),
                      'emoji': selectedEmoji,
                      'category': selectedCategory,
                      'image_url': imageUrl,
                      'is_active': true,
                    };
                    
                    if (isEdit) {
                      await SupabaseService.client
                          .from('products')
                          .update(data)
                          .eq('id', product['id']);
                    } else {
                      await SupabaseService.client
                          .from('products')
                          .insert(data);
                    }
                    
                    ref.invalidate(productsProvider);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? 'Product updated!' : 'Product added!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() {
                      isLoading = false;
                      errorMessage = 'Error: ${e.toString()}';
                    });
                    debugPrint('Product save error: $e');
                  }
                },
                child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleStatus(Map<String, dynamic> product) async {
    final newStatus = !(product['is_active'] ?? true);
    await SupabaseService.client
        .from('products')
        .update({'is_active': newStatus})
        .eq('id', product['id']);
    ref.invalidate(productsProvider);
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
            onPressed: () async {
              await SupabaseService.client
                  .from('products')
                  .delete()
                  .eq('id', product['id']);
              ref.invalidate(productsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
