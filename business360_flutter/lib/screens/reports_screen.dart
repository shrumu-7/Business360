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
    final currency = store.prefs.getString('currency') ?? '৳';
    final threshold = store.prefs.getInt('lowStock') ?? 5;

    final revenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final paid = sales.fold<double>(0, (sum, sale) => sum + sale.paid);
    final due = customers.fold<double>(0, (sum, customer) => sum + customer.due);
    final profit = sales.fold<double>(0, (sum, sale) => sum + sale.profit);
    final stockValue = products.fold<double>(
      0,
      (sum, product) => sum + product.cost * product.stock,
    );
    final lowStock = products.where((p) => p.stock <= threshold).toList();
    final now = DateTime.now();
    final todaySales = sales
        .where(
          (sale) =>
              sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day,
        )
        .fold<double>(0, (sum, sale) => sum + sale.total);

    Widget metric(String label, double value, IconData icon) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: Text(
            '$currency${value.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Business Reports',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        metric('Total sales', revenue, Icons.trending_up),
        metric('Collected', paid, Icons.payments),
        metric('Outstanding due', due, Icons.account_balance_wallet),
        metric('Gross profit', profit, Icons.show_chart),
        metric("Today's sales", todaySales, Icons.today),
        metric('Stock value', stockValue, Icons.inventory_2),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Products: ${products.length}'),
                Text('Customers: ${customers.length}'),
                Text('Sales transactions: ${sales.length}'),
                Text('Low-stock products: ${lowStock.length}'),
              ],
            ),
          ),
        ),
        if (lowStock.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Low stock alert',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...lowStock.take(15).map(
                        (product) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(product.name),
                          trailing: Text(
                            '${product.stock.toStringAsFixed(0)} ${product.unit}',
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
