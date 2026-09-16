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
  String filter = 'All';
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
    if (ok != true || name.text.trim().isEmpty) { for(final c in [name,category,price,cost,stock,unit]) c.dispose(); return; }
    final product = old ?? Product(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name.text.trim(), price: 0, stock: 0);
    product.name = name.text.trim(); product.category = category.text.trim(); product.price = double.tryParse(price.text) ?? 0; product.cost = double.tryParse(cost.text) ?? 0; product.stock = double.tryParse(stock.text) ?? 0; product.unit = unit.text.trim().isEmpty ? 'pcs' : unit.text.trim();
    setState(() { if (old == null) items.add(product); });
    await widget.store.saveProducts(items);
    for(final c in [name,category,price,cost,stock,unit]) c.dispose();
  }

  Future<void> remove(Product product) async { setState(() => items.remove(product)); await widget.store.saveProducts(items); }

  @override Widget build(BuildContext context) {
    final threshold = widget.store.prefs.getInt('lowStock') ?? 5;
    final currency = widget.store.prefs.getString('currency') ?? '৳';
    final categories = ['All', ...{for (final p in items) if (p.category.trim().isNotEmpty) p.category.trim()}];
    final shown = filter == 'All' ? items : items.where((p) => p.category.trim() == filter).toList();
    if (!categories.contains(filter)) filter = 'All';
    return Scaffold(
      appBar: AppBar(title: const Text('Products & Stock')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => addOrEdit(), icon: const Icon(Icons.add), label: const Text('Product')),
      body: Column(children: [
        if (categories.length > 1) SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [for (final c in categories) Padding(padding: const EdgeInsets.only(right: 8, top: 8), child: ChoiceChip(label: Text(c), selected: filter == c, onSelected: (_) => setState(() => filter = c)))])),
        Expanded(child: shown.isEmpty ? const Center(child: Text('No products yet')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: shown.length, itemBuilder: (context, i) {
          final p = shown[i]; final low = p.stock <= threshold;
          return Card(child: ListTile(
            leading: CircleAvatar(child: Icon(low ? Icons.warning_amber : Icons.inventory_2)),
            title: Text(p.name),
            subtitle: Text('${p.category.isEmpty ? 'No category' : p.category} • Stock: ${p.stock} ${p.unit} • Cost: $currency${p.cost.toStringAsFixed(2)} • Sell: $currency${p.price.toStringAsFixed(2)}${low ? ' • LOW STOCK' : ''}'),
            trailing: Wrap(children: [IconButton(onPressed: () => addOrEdit(p), icon: const Icon(Icons.edit)), IconButton(onPressed: () => remove(p), icon: const Icon(Icons.delete_outline))]),
          ));
        })),
      ]),
    );
  }
}
