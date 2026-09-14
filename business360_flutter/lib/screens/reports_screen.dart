import 'package:flutter/material.dart';
import '../services/business_store.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.store});
  final BusinessStore store;

  @override
  Widget build(BuildContext context) {
    final products = store.products;
    final customers = store.customers;
    final sales = store.sales;
    final revenue = sales.fold<double>(0, (s, x) => s + x.total);
    final paid = sales.fold<double>(0, (s, x) => s + x.paid);
    final due = customers.fold<double>(0, (s, x) => s + x.due);
    final profit = sales.fold<double>(0, (s, x) => s + x.profit);
    final stockValue = products.fold<double>(0, (s, x) => s + x.cost * x.stock);
    final lowStock = products.where((p) => p.stock <= 5).toList();
    final today = DateTime.now();
    final todaySales = sales.where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day).fold<double>(0, (a, s) => a + s.total);

    Widget metric(String label, String value, IconData icon) => Card(child: ListTile(leading: Icon(icon), title: Text(label), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Business Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      metric('Total sales', '৳${revenue.toStringAsFixed(2)}', Icons.trending_up),
      metric('Collected', '৳${paid.toStringAsFixed(2)}', Icons.payments),
      metric('Outstanding due', '৳${due.toStringAsFixed(2)}', Icons.account_balance_wallet),
      metric('Gross profit', '৳${profit.toStringAsFixed(2)}', Icons.show_chart),
      metric("Today's sales", '৳${todaySales.toStringAsFixed(2)}', Icons.today),
      metric('Stock value', '৳${stockValue.toStringAsFixed(2)}', Icons.inventory_2),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('Products: ${products.length}'), Text('Customers: ${customers.length}'), Text('Sales transactions: ${sales.length}'),
        Text('Low-stock products: ${lowStock.length}'),
      ]))),
      if (lowStock.isNotEmpty) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Low stock alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lowStock.take(15).map((p) => ListTile(contentPadding: EdgeInsets.zero, title: Text(p.name), trailing: Text('${p.stock.toStringAsFixed(0)} ${p.unit}'))),
        ]))),
      ],
    ]);
  }
}
