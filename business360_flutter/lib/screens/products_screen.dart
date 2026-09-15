import 'package:flutter/material.dart';
import '../models/business_models.dart';
import '../services/business_store.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.store});
  final BusinessStore store;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late List<Product> items;

  @override
  void initState() {
    super.initState();
    items = widget.store.products;
  }

  Future<void> addOrEdit([Product? old]) async {
    final name = TextEditingController(text: old?.name ?? '');
    final price = TextEditingController(text: old?.price.toString() ?? '');
    final stock = TextEditingController(text: old?.stock.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(old == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Product name'),
              ),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Selling price'),
              ),
              TextField(
                controller: stock,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true || name.text.trim().isEmpty) return;

    setState(() {
      if (old == null) {
        items.add(
          Product(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name.text.trim(),
            price: double.tryParse(price.text) ?? 0,
            stock: double.tryParse(stock.text) ?? 0,
          ),
        );
      } else {
        old.name = name.text.trim();
        old.price = double.tryParse(price.text) ?? 0;
        old.stock = double.tryParse(stock.text) ?? 0;
      }
    });

    await widget.store.saveProducts(items);
  }

  Future<void> remove(Product product) async {
    setState(() => items.remove(product));
    await widget.store.saveProducts(items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products & Stock')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No products yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final product = items[i];
                return Card(
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      'Stock: ${product.stock}  •  Price: ৳${product.price.toStringAsFixed(2)}',
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          onPressed: () => addOrEdit(product),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () => remove(product),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
