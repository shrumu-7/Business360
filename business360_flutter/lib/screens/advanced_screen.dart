import 'package:flutter/material.dart';
import '../models/business_models.dart';
import '../services/business_store.dart';

class AdvancedScreen extends StatefulWidget {
  const AdvancedScreen({super.key, required this.store});
  final BusinessStore store;

  @override
  State<AdvancedScreen> createState() => _AdvancedScreenState();
}

class _AdvancedScreenState extends State<AdvancedScreen> {
  int tab = 0;

  String money(double value) =>
      '${widget.store.prefs.getString('currency') ?? '৳'}${value.toStringAsFixed(2)}';

  String makeId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> supplierDialog([Supplier? old]) async {
    final name = TextEditingController(text: old?.name ?? '');
    final phone = TextEditingController(text: old?.phone ?? '');
    final address = TextEditingController(text: old?.address ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(old == null ? 'Add supplier' : 'Edit supplier'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final list = widget.store.suppliers;
              final item = Supplier(
                id: old?.id ?? makeId(),
                name: name.text.trim(),
                phone: phone.text.trim(),
                address: address.text.trim(),
                due: old?.due ?? 0,
              );
              if (old == null) {
                list.add(item);
              } else {
                final index = list.indexWhere((e) => e.id == old.id);
                if (index >= 0) list[index] = item;
              }
              await widget.store.saveSuppliers(list);
              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    address.dispose();
  }

  Future<void> paymentDialog() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    String type = 'received';
    String party = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final customers = widget.store.customers;
          final suppliers = widget.store.suppliers;
          final parties = type == 'received' ? customers : suppliers;
          return AlertDialog(
            title: const Text('Add payment'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(value: 'received', child: Text('Received from customer')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid to supplier')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          type = value;
                          party = '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: party.isEmpty ? null : party,
                    items: [
                      for (final item in parties)
                        DropdownMenuItem(value: item.id, child: Text(item.name)),
                    ],
                    onChanged: (value) => setDialogState(() => party = value ?? ''),
                    decoration: const InputDecoration(labelText: 'Party'),
                  ),
                  TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(amount.text) ?? 0;
                  if (value <= 0 || party.isEmpty) return;
                  final payment = Payment(
                    id: makeId(),
                    date: DateTime.now(),
                    partyId: party,
                    amount: value,
                    note: note.text.trim(),
                    type: type,
                  );
                  widget.store.payments.add(payment);
                  await widget.store.savePayments(widget.store.payments);
                  if (type == 'received') {
                    final list = widget.store.customers;
                    final index = list.indexWhere((e) => e.id == party);
                    if (index >= 0) {
                      list[index].due -= value;
                      await widget.store.saveCustomers(list);
                    }
                  } else {
                    final list = widget.store.suppliers;
                    final index = list.indexWhere((e) => e.id == party);
                    if (index >= 0) {
                      list[index].due -= value;
                      await widget.store.saveSuppliers(list);
                    }
                  }
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    amount.dispose();
    note.dispose();
  }

  Future<void> stockMoveDialog() async {
    String product = '';
    String type = 'in';
    final quantity = TextEditingController();
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Stock movement'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: product.isEmpty ? null : product,
                  items: [
                    for (final item in widget.store.products)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) => setDialogState(() => product = value ?? ''),
                  decoration: const InputDecoration(labelText: 'Product'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 'in', child: Text('Stock In')),
                    DropdownMenuItem(value: 'out', child: Text('Stock Out')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
                TextField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final value = double.tryParse(quantity.text) ?? 0;
                if (product.isEmpty || value <= 0) return;
                final list = widget.store.products;
                final index = list.indexWhere((e) => e.id == product);
                if (index < 0) return;
                final delta = type == 'out' ? -value : value;
                list[index].stock = type == 'adjustment'
                    ? value
                    : list[index].stock + delta;
                if (list[index].stock < 0) list[index].stock = 0;
                await widget.store.saveProducts(list);
                widget.store.stockMoves.add(
                  StockMove(
                    id: makeId(),
                    date: DateTime.now(),
                    productId: product,
                    quantity: value,
                    type: type,
                    note: note.text.trim(),
                  ),
                );
                await widget.store.saveStockMoves(widget.store.stockMoves);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    quantity.dispose();
    note.dispose();
  }

  Future<void> returnDialog() async {
    final quantity = TextEditingController();
    final note = TextEditingController();
    String sale = '';
    String product = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedSales = widget.store.sales.where((e) => e.id == sale).toList();
          final items = selectedSales.isEmpty ? <SaleItem>[] : selectedSales.first.items;
          return AlertDialog(
            title: const Text('Sales return'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: sale.isEmpty ? null : sale,
                    items: [
                      for (final item in widget.store.sales)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text('#${item.id.substring(item.id.length - 6)} • ${money(item.total)}'),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        sale = value ?? '';
                        product = '';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Sale'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: product.isEmpty ? null : product,
                    items: [
                      for (final item in items)
                        DropdownMenuItem(value: item.productId, child: Text(item.name)),
                    ],
                    onChanged: (value) => setDialogState(() => product = value ?? ''),
                    decoration: const InputDecoration(labelText: 'Product'),
                  ),
                  TextField(
                    controller: quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(quantity.text) ?? 0;
                  final sales = widget.store.sales.where((e) => e.id == sale).toList();
                  final saleItems = sales.isEmpty
                      ? <SaleItem>[]
                      : sales.first.items.where((e) => e.productId == product).toList();
                  if (sales.isEmpty || saleItems.isEmpty || value <= 0 || value > saleItems.first.quantity) {
                    return;
                  }
                  final amount = value * saleItems.first.price;
                  final products = widget.store.products;
                  final productIndex = products.indexWhere((e) => e.id == product);
                  if (productIndex >= 0) {
                    products[productIndex].stock += value;
                    await widget.store.saveProducts(products);
                  }
                  widget.store.returns.add(
                    ReturnRecord(
                      id: makeId(),
                      date: DateTime.now(),
                      saleId: sale,
                      productId: product,
                      quantity: value,
                      amount: amount,
                      note: note.text.trim(),
                    ),
                  );
                  await widget.store.saveReturns(widget.store.returns);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  setState(() {});
                },
                child: const Text('Save return'),
              ),
            ],
          );
        },
      ),
    );
    quantity.dispose();
    note.dispose();
  }

  void receipt(Sale sale) {
    final shop = widget.store.prefs.getString('shop') ?? 'আমার দোকান';
    final currency = widget.store.prefs.getString('currency') ?? '৳';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$shop — Invoice ${sale.id.substring(sale.id.length - 6)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${sale.date}'),
              const Divider(),
              for (final item in sale.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.name} × ${item.quantity}')),
                      Text('$currency${item.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              const Divider(),
              Text('Total: $currency${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Paid: $currency${sale.paid.toStringAsFixed(2)}'),
              Text('Due: $currency${sale.due.toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = widget.store.suppliers;
    final payments = widget.store.payments;
    final returns = widget.store.returns;
    final moves = widget.store.stockMoves;
    final sales = widget.store.sales;
    const tabs = ['Suppliers', 'Payments', 'Returns', 'Stock Moves', 'Invoices'];

    return Scaffold(
      appBar: AppBar(title: const Text('Business Tools')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: Text(tabs[i]),
                      selected: tab == i,
                      onSelected: (_) => setState(() => tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (tab == 0)
                  for (final supplier in suppliers)
                    Card(
                      child: ListTile(
                        title: Text(supplier.name),
                        subtitle: Text('${supplier.phone}\nDue: ${money(supplier.due)}'),
                        isThreeLine: true,
                        onTap: () => supplierDialog(supplier),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            widget.store.suppliers.removeWhere((e) => e.id == supplier.id);
                            await widget.store.saveSuppliers(widget.store.suppliers);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ),
                if (tab == 1)
                  for (final payment in payments)
                    Card(
                      child: ListTile(
                        title: Text('${payment.type == 'received' ? 'Received' : 'Paid'} ${money(payment.amount)}'),
                        subtitle: Text('${payment.date}\n${payment.note}'),
                        isThreeLine: true,
                      ),
                    ),
                if (tab == 2)
                  for (final item in returns)
                    Card(
                      child: ListTile(
                        title: Text('Return ${money(item.amount)} • Qty ${item.quantity}'),
                        subtitle: Text('Sale ${item.saleId} • Product ${item.productId}'),
                      ),
                    ),
                if (tab == 3)
                  for (final move in moves)
                    Card(
                      child: ListTile(
                        title: Text('${move.type.toUpperCase()} • ${move.quantity}'),
                        subtitle: Text('Product ${move.productId}\n${move.date}'),
                        isThreeLine: true,
                      ),
                    ),
                if (tab == 4)
                  for (final sale in sales)
                    Card(
                      child: ListTile(
                        title: Text('Invoice ${sale.id.substring(sale.id.length - 6)}'),
                        subtitle: Text('${sale.date} • ${money(sale.total)}'),
                        trailing: FilledButton(onPressed: () => receipt(sale), child: const Text('View')),
                      ),
                    ),
                if (tab == 0 && suppliers.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No suppliers yet'))),
                if (tab == 1 && payments.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No payments yet'))),
                if (tab == 2 && returns.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No returns yet'))),
                if (tab == 3 && moves.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No stock movements yet'))),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(onPressed: supplierDialog, icon: const Icon(Icons.person_add), label: const Text('Supplier'))
          : tab == 1
              ? FloatingActionButton.extended(onPressed: paymentDialog, icon: const Icon(Icons.payments), label: const Text('Payment'))
              : tab == 2
                  ? FloatingActionButton.extended(onPressed: returnDialog, icon: const Icon(Icons.assignment_return), label: const Text('Return'))
                  : tab == 3
                      ? FloatingActionButton.extended(onPressed: stockMoveDialog, icon: const Icon(Icons.swap_vert), label: const Text('Stock move'))
                      : null,
    );
  }
}
