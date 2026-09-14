import 'package:flutter/material.dart';
import '../models/business_models.dart';
import '../services/business_store.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.store});
  final BusinessStore store;
  @override State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late List<Product> products;
  late List<Customer> customers;
  late List<Sale> sales;
  final Map<String, double> cart = {};
  String customerId = '';
  final paidController = TextEditingController();
  @override void initState() { super.initState(); _reload(); }
  void _reload() { products = widget.store.products; customers = widget.store.customers; sales = widget.store.sales; }
  double get total => cart.entries.fold(0, (sum, e) { final p = products.firstWhere((x) => x.id == e.key); return sum + p.price * e.value; });
  Future<void> checkout() async {
    if (cart.isEmpty) return;
    final paid = double.tryParse(paidController.text) ?? 0;
    if (paid < 0 || paid > total) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paid amount must be between 0 and total.'))); return; }
    for (final e in cart.entries) { final p = products.firstWhere((x) => x.id == e.key); p.stock = (p.stock - e.value).clamp(0, double.infinity); }
    final sale = Sale(id: DateTime.now().microsecondsSinceEpoch.toString(), date: DateTime.now(), total: total, paid: paid, customerId: customerId);
    sales.add(sale);
    if (customerId.isNotEmpty && sale.due > 0) customers.firstWhere((x) => x.id == customerId).due += sale.due;
    await widget.store.saveProducts(products); await widget.store.saveSales(sales); await widget.store.saveCustomers(customers);
    setState(() { cart.clear(); paidController.clear(); customerId = ''; _reload(); });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale saved • Due: ৳${sale.due.toStringAsFixed(2)}')));
  }
  void add(Product p) { final current = cart[p.id] ?? 0; if (current < p.stock) setState(() => cart[p.id] = current + 1); }
  void remove(Product p) { final current = cart[p.id] ?? 0; if (current <= 1) setState(() => cart.remove(p.id)); else setState(() => cart[p.id] = current - 1); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Sales / POS')), body: products.isEmpty ? const Center(child: Text('Add products first.')) : ListView(padding: const EdgeInsets.all(12), children: [
    Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), ...products.map((p) => ListTile(title: Text(p.name), subtitle: Text('৳${p.price.toStringAsFixed(2)} • Stock ${p.stock.toStringAsFixed(0)}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: (cart[p.id] ?? 0) > 0 ? () => remove(p) : null, icon: const Icon(Icons.remove_circle_outline)), Text('${cart[p.id] ?? 0}'), IconButton(onPressed: () => add(p), icon: const Icon(Icons.add_circle_outline))])))]))),
    Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [DropdownButtonFormField<String>(value: customerId.isEmpty ? null : customerId, decoration: const InputDecoration(labelText: 'Customer (optional)'), items: [const DropdownMenuItem(value: '', child: Text('Walk-in customer')), ...customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))], onChanged: (v) => setState(() => customerId = v ?? '')), const SizedBox(height: 12), TextField(controller: paidController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Paid amount', prefixText: '৳ ')), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('৳${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: cart.isEmpty ? null : checkout, icon: const Icon(Icons.check), label: const Text('Complete Sale')))]))),
    const SizedBox(height: 8), const Text('Recent sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), ...sales.reversed.take(20).map((s) => ListTile(title: Text('৳${s.total.toStringAsFixed(2)}'), subtitle: Text('${s.date.toLocal()} • Paid ৳${s.paid.toStringAsFixed(2)}'), trailing: Text('Due ৳${s.due.toStringAsFixed(2)}')))
  ]));
  @override void dispose() { paidController.dispose(); super.dispose(); }
}
