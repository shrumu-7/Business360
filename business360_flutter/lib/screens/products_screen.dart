import 'package:flutter/material.dart';
import '../models/business_models.dart';
import '../services/business_store.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.store});
  final BusinessStore store;
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late List<Product> items;
  @override void initState() { super.initState(); items = widget.store.products; }

  Future<void> addOrEdit([Product? old]) async {
    final name = TextEditingController(text: old?.name ?? '');
    final category = TextEditingController(text: old?.category ?? '');
    final price = TextEditingController(text: old?.price.toString() ?? '');
    final cost = TextEditingController(text: old?.cost.toString() ?? '');
    final stock = TextEditingController(text: old?.stock.toString() ?? '');
    final unit = TextEditingController(text: old?.unit ?? 'pcs');
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(old == null ? 'Add Product' : 'Edit Product'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Product name')),
        TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
        TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling price')),
        TextField(controller: cost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cost price')),
        TextField(controller: stock, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Stock')),
        TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit (pcs/kg/etc.)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save'))],
    ));
    if (ok != true || name.text.trim().isEmpty) return;
    final product = old ?? Product(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name.text.trim(), price: 0, stock: 0);
    product.name = name.text.trim(); product.category = category.text.trim(); product.price = double.tryParse(price.text) ?? 0; product.cost = double.tryParse(cost.text) ?? 0; product.stock = double.tryParse(stock.text) ?? 0; product.unit = unit.text.trim().isEmpty ? 'pcs' : unit.text.trim();
    setState(() { if (old == null) items.add(product); });
    await widget.store.saveProducts(items);
  }

  Future<void> remove(Product product) async { setState(() => items.remove(product)); await widget.store.saveProducts(items); }

  @override Widget build(BuildContext context) {
    final threshold = widget.store.prefs.getInt('lowStock') ?? 5;
    return Scaffold(
      appBar: AppBar(title: const Text('Products & Stock')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => addOrEdit(), icon: const Icon(Icons.add), label: const Text('Product')),
      body: items.isEmpty ? const Center(child: Text('No products yet')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (context, i) {
        final p = items[i]; final low = p.stock <= threshold;
        return Card(child: ListTile(
          leading: CircleAvatar(child: Icon(low ? Icons.warning_amber : Icons.inventory_2)),
          title: Text(p.name),
          subtitle: Text('${p.category.isEmpty ? 'No category' : p.category} • Stock: ${p.stock} ${p.unit} • Cost: ৳${p.cost.toStringAsFixed(2)} • Sell: ৳${p.price.toStringAsFixed(2)}${low ? ' • LOW STOCK' : ''}'),
          trailing: Wrap(children: [IconButton(onPressed: () => addOrEdit(p), icon: const Icon(Icons.edit)), IconButton(onPressed: () => remove(p), icon: const Icon(Icons.delete_outline))]),
        ));
      }),
    );
  }
}
