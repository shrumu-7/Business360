import 'package:flutter/material.dart';

import '../models/business_models.dart';
import '../services/business_store.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.store});

  final BusinessStore store;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late List<Product> products;
  late List<Customer> customers;
  late List<Sale> sales;
  final Map<String, double> cart = {};
  String customerId = '';
  final paidController = TextEditingController();

  String get currency => widget.store.prefs.getString('currency') ?? '৳';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    products = widget.store.products;
    customers = widget.store.customers;
    sales = widget.store.sales;
  }

  double get total => cart.entries.fold<double>(0, (sum, entry) {
        final product = products.firstWhere((item) => item.id == entry.key);
        return sum + product.price * entry.value;
      });

  double get cartProfit => cart.entries.fold<double>(0, (sum, entry) {
        final product = products.firstWhere((item) => item.id == entry.key);
        return sum + (product.price - product.cost) * entry.value;
      });

  Future<void> checkout() async {
    if (cart.isEmpty) return;

    final paid = double.tryParse(paidController.text.trim()) ?? 0;
    if (paid < 0 || paid > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paid amount must be between 0 and total.')),
      );
      return;
    }

    final items = <SaleItem>[];
    for (final entry in cart.entries) {
      final product = products.firstWhere((item) => item.id == entry.key);
      if (entry.value > product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for ${product.name}.')),
        );
        return;
      }
      items.add(
        SaleItem(
          productId: product.id,
          name: product.name,
          quantity: entry.value,
          price: product.price,
          cost: product.cost,
        ),
      );
    }

    for (final entry in cart.entries) {
      final product = products.firstWhere((item) => item.id == entry.key);
      product.stock -= entry.value;
    }

    final sale = Sale(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      total: total,
      paid: paid,
      customerId: customerId,
      items: items,
    );

    sales.add(sale);
    if (customerId.isNotEmpty && sale.due > 0) {
      customers.firstWhere((item) => item.id == customerId).due += sale.due;
    }

    await widget.store.saveProducts(products);
    await widget.store.saveSales(sales);
    await widget.store.saveCustomers(customers);

    setState(() {
      cart.clear();
      paidController.clear();
      customerId = '';
      _reload();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sale saved • Due: $currency${sale.due.toStringAsFixed(2)} • Profit: $currency${sale.profit.toStringAsFixed(2)}',
          ),
        ),
      );
    }
  }

  void add(Product product) {
    final current = cart[product.id] ?? 0;
    if (current < product.stock) {
      setState(() => cart[product.id] = current + 1);
    }
  }

  void remove(Product product) {
    final current = cart[product.id] ?? 0;
    if (current <= 1) {
      setState(() => cart.remove(product.id));
    } else {
      setState(() => cart[product.id] = current - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales / POS')),
      body: products.isEmpty
          ? const Center(child: Text('Add products first.'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Products',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ...products.map(
                          (product) => ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '$currency${product.price.toStringAsFixed(2)} • Stock ${product.stock.toStringAsFixed(0)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: (cart[product.id] ?? 0) > 0
                                      ? () => remove(product)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${cart[product.id] ?? 0}'),
                                IconButton(
                                  onPressed: () => add(product),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: customerId.isEmpty ? null : customerId,
                          decoration: const InputDecoration(
                            labelText: 'Customer (optional)',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Walk-in customer'),
                            ),
                            ...customers.map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(customer.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => customerId = value ?? ''),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: paidController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Paid amount',
                            prefixText: '$currency ',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$currency${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Estimated profit: $currency${cartProfit.toStringAsFixed(2)}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: cart.isEmpty ? null : checkout,
                            icon: const Icon(Icons.check),
                            label: const Text('Complete Sale'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recent sales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...sales.reversed.take(20).map(
                      (sale) => Card(
                        child: ListTile(
                          title: Text(
                            '$currency${sale.total.toStringAsFixed(2)}',
                          ),
                          subtitle: Text(
                            '${sale.date.toLocal()} • ${sale.items.length} item types • Paid $currency${sale.paid.toStringAsFixed(2)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Due $currency${sale.due.toStringAsFixed(2)}'),
                              Text(
                                'Profit $currency${sale.profit.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    paidController.dispose();
    super.dispose();
  }
}
