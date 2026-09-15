import 'package:flutter/material.dart';

import '../models/business_models.dart';
import '../services/business_store.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key, required this.store});

  final BusinessStore store;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int tab = 0;

  String get currency => widget.store.prefs.getString('currency') ?? '৳';

  void addExpense() {
    final title = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    _dialog(
      'Add Expense',
      [title, amount, note],
      ['Title', 'Amount', 'Note'],
      () {
        final value = double.tryParse(amount.text);
        if (title.text.trim().isEmpty || value == null || value <= 0) return;
        final list = widget.store.expenses;
        list.add(
          BusinessExpense(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            date: DateTime.now(),
            title: title.text.trim(),
            amount: value,
            note: note.text.trim(),
          ),
        );
        widget.store.saveExpenses(list);
        setState(() {});
      },
    );
  }

  void addPurchase() {
    final supplier = TextEditingController();
    final amount = TextEditingController();
    final paid = TextEditingController();
    final note = TextEditingController();
    _dialog(
      'Add Purchase',
      [supplier, amount, paid, note],
      ['Supplier', 'Amount', 'Paid', 'Note'],
      () {
        final value = double.tryParse(amount.text);
        final paidValue = double.tryParse(paid.text.isEmpty ? '0' : paid.text);
        if (supplier.text.trim().isEmpty ||
            value == null ||
            value <= 0 ||
            paidValue == null ||
            paidValue < 0 ||
            paidValue > value) {
          return;
        }
        final list = widget.store.purchases;
        list.add(
          Purchase(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            date: DateTime.now(),
            supplier: supplier.text.trim(),
            amount: value,
            paid: paidValue,
            note: note.text.trim(),
          ),
        );
        widget.store.savePurchases(list);
        setState(() {});
      },
    );
  }

  void _dialog(
    String title,
    List<TextEditingController> controllers,
    List<String> labels,
    VoidCallback save,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < controllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[i],
                      keyboardType: i == 0 || labels[i] == 'Note'
                          ? TextInputType.text
                          : const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: labels[i],
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                save();
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = widget.store.expenses.reversed.toList();
    final purchases = widget.store.purchases.reversed.toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('Expenses'),
                  icon: Icon(Icons.receipt_long),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Purchases'),
                  icon: Icon(Icons.shopping_cart),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (selection) {
                setState(() => tab = selection.first);
              },
            ),
          ),
          Expanded(
            child: tab == 0
                ? ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _summary(
                        'Total expense',
                        expenses.fold<double>(0, (sum, item) => sum + item.amount),
                      ),
                      ...expenses.map(
                        (expense) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.money_off),
                            title: Text(expense.title),
                            subtitle: Text(expense.date.toString().split('.').first),
                            trailing: Text(
                              '$currency${expense.amount.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _summary(
                        'Purchase due',
                        purchases.fold<double>(0, (sum, item) => sum + item.due),
                      ),
                      ...purchases.map(
                        (purchase) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.shopping_cart),
                            title: Text(purchase.supplier),
                            subtitle: Text(
                              'Paid $currency${purchase.paid.toStringAsFixed(2)} • Due $currency${purchase.due.toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              '$currency${purchase.amount.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: tab == 0 ? addExpense : addPurchase,
        icon: const Icon(Icons.add),
        label: Text(tab == 0 ? 'Expense' : 'Purchase'),
      ),
    );
  }

  Widget _summary(String title, double value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$currency${value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
