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
          child: Column(children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final list = widget.store.suppliers;
              final item = Supplier(
                id: old?.id ?? makeId(), name: name.text.trim(),
                phone: phone.text.trim(), address: address.text.trim(), due: old?.due ?? 0,
              );
              final index = old == null ? -1 : list.indexWhere((e) => e.id == old.id);
              if (index >= 0) {
                list[index] = item;
              } else {
                list.add(item);
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
    name.dispose(); phone.dispose(); address.dispose();
  }

  Future<void> paymentDialog() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    String type = 'received';
    String party = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final customers = widget.store.customers;
          final suppliers = widget.store.suppliers;
          return AlertDialog(
            title: const Text('Add payment'),
            content: SingleChildScrollView(
              child: Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 'received', child: Text('Received from customer')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid to supplier')),
                  ],
                  onChanged: (v) => setDialogState(() { type = v ?? 'received'; party = ''; }),
                ),
                DropdownButtonFormField<String>(
                  initialValue: party.isEmpty ? null : party,
                  items: type == 'received'
                      ? [for (final c in customers) DropdownMenuItem(value: c.id, child: Text(c.name))]
                      : [for (final s in suppliers) DropdownMenuItem(value: s.id, child: Text(s.name))],
                  onChanged: (v) => setDialogState(() => party = v ?? ''),
                  decoration: const InputDecoration(labelText: 'Party'),
                ),
                TextField(controller: amount, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount')),
                TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(amount.text) ?? 0;
                  if (value <= 0 || party.isEmpty) return;
                  widget.store.payments.add(Payment(
                    id: makeId(), date: DateTime.now(), partyId: party,
                    amount: value, note: note.text.trim(), type: type,
                  ));
                  await widget.store.savePayments(widget.store.payments);
                  if (type == 'received') {
                    final list = widget.store.customers;
                    final i = list.indexWhere((e) => e.id == party);
                    if (i >= 0) { list[i].due -= value; await widget.store.saveCustomers(list); }
                  } else {
                    final list = widget.store.suppliers;
                    final i = list.indexWhere((e) => e.id == party);
                    if (i >= 0) { list[i].due -= value; await widget.store.saveSuppliers(list); }
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
    amount.dispose(); note.dispose();
  }

  Future<void> stockMoveDialog() async {
    String product = '';
    String type = 'in';
    final quantity = TextEditingController();
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Stock movement'),
          content: SingleChildScrollView(child: Column(children: [
            DropdownButtonFormField<String>(
              initialValue: product.isEmpty ? null : product,
              items: [for (final p in widget.store.products) DropdownMenuItem(value: p.id, child: Text(p.name))],
              onChanged: (v) => setDialogState(() => product = v ?? ''),
              decoration: const InputDecoration(labelText: 'Product'),
            ),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: const [
                DropdownMenuItem(value: 'in', child: Text('Stock In')),
                DropdownMenuItem(value: 'out', child: Text('Stock Out')),
                DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
              ],
              onChanged: (v) => setDialogState(() => type = v ?? 'in'),
            ),
            TextField(controller: quantity, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity')),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final value = double.tryParse(quantity.text) ?? 0;
                final list = widget.store.products;
                final i = list.indexWhere((e) => e.id == product);
                if (i < 0 || value <= 0) return;
                if (type == 'adjustment') {
                  list[i].stock = value;
                } else {
                  list[i].stock += type == 'out' ? -value : value;
                  if (list[i].stock < 0) list[i].stock = 0;
                }
                await widget.store.saveProducts(list);
                widget.store.stockMoves.add(StockMove(
                  id: makeId(), date: DateTime.now(), productId: product,
                  quantity: value, type: type, note: note.text.trim(),
                ));
                await widget.store.saveStockMoves(widget.store.stockMoves);
                if (!mounted) return;
                Navigator.pop(dialogContext); setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    quantity.dispose(); note.dispose();
  }

  Future<void> returnDialog() async {
    String sale = '';
    String product = '';
    final quantity = TextEditingController();
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final selected = widget.store.sales.where((s) => s.id == sale).toList();
          final items = selected.isEmpty ? <SaleItem>[] : selected.first.items;
          return AlertDialog(
            title: const Text('Sales return'),
            content: SingleChildScrollView(child: Column(children: [
              DropdownButtonFormField<String>(
                initialValue: sale.isEmpty ? null : sale,
                items: [for (final s in widget.store.sales)
                  DropdownMenuItem(value: s.id, child: Text('#${s.id.substring(s.id.length - 6)} • ${money(s.total)}'))],
                onChanged: (v) => setDialogState(() { sale = v ?? ''; product = ''; }),
                decoration: const InputDecoration(labelText: 'Sale'),
              ),
              DropdownButtonFormField<String>(
                initialValue: product.isEmpty ? null : product,
                items: [for (final i in items) DropdownMenuItem(value: i.productId, child: Text(i.name))],
                onChanged: (v) => setDialogState(() => product = v ?? ''),
                decoration: const InputDecoration(labelText: 'Product'),
              ),
              TextField(controller: quantity, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity')),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(quantity.text) ?? 0;
                  final sales = widget.store.sales.where((s) => s.id == sale).toList();
                  final saleItems = sales.isEmpty ? <SaleItem>[] : sales.first.items.where((i) => i.productId == product).toList();
                  if (saleItems.isEmpty || value <= 0 || value > saleItems.first.quantity) return;
                  final amount = value * saleItems.first.price;
                  final products = widget.store.products;
                  final pi = products.indexWhere((p) => p.id == product);
                  if (pi >= 0) { products[pi].stock += value; await widget.store.saveProducts(products); }
                  widget.store.returns.add(ReturnRecord(
                    id: makeId(), date: DateTime.now(), saleId: sale, productId: product,
                    quantity: value, amount: amount, note: note.text.trim(),
                  ));
                  await widget.store.saveReturns(widget.store.returns);
                  if (!mounted) return;
                  Navigator.pop(dialogContext); setState(() {});
                },
                child: const Text('Save return'),
              ),
            ],
          );
        },
      ),
    );
    quantity.dispose(); note.dispose();
  }

  void receipt(Sale sale) {
    final shop = widget.store.prefs.getString('shop') ?? 'আমার দোকান';
    final currency = widget.store.prefs.getString('currency') ?? '৳';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$shop — Invoice ${sale.id.substring(sale.id.length - 6)}'),
        content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Date: ${sale.date}'), const Divider(),
          for (final item in sale.items)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('${item.name} × ${item.quantity}')),
              Text('$currency${item.subtotal.toStringAsFixed(2)}'),
            ]),
          const Divider(),
          Text('Total: $currency${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Paid: $currency${sale.paid.toStringAsFixed(2)}'),
          Text('Due: $currency${sale.due.toStringAsFixed(2)}'),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Suppliers', 'Payments', 'Returns', 'Stock Moves', 'Invoices'];
    final suppliers = widget.store.suppliers;
    final payments = widget.store.payments;
    final returns = widget.store.returns;
    final moves = widget.store.stockMoves;
    final sales = widget.store.sales;
    return Scaffold(
      appBar: AppBar(title: const Text('Business Tools')),
      body: Column(children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (var i = 0; i < tabs.length; i++) Padding(
            padding: const EdgeInsets.all(4),
            child: ChoiceChip(label: Text(tabs[i]), selected: tab == i, onSelected: (_) => setState(() => tab = i)),
          ),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
          if (tab == 0) ...[
            for (final s in suppliers) Card(child: ListTile(
              title: Text(s.name), subtitle: Text('${s.phone}\nDue: ${money(s.due)}'), isThreeLine: true,
              onTap: () => supplierDialog(s), trailing: IconButton(
                icon: const Icon(Icons.delete), onPressed: () async {
                  suppliers.removeWhere((e) => e.id == s.id); await widget.store.saveSuppliers(suppliers); if (mounted) setState(() {});
                },
              ),
            )),
            if (suppliers.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No suppliers yet'))),
          ],
          if (tab == 1) ...[
            for (final p in payments) Card(child: ListTile(
              title: Text('${p.type == 'received' ? 'Received' : 'Paid'} ${money(p.amount)}'),
              subtitle: Text('${p.date}\n${p.note}'), isThreeLine: true,
            )),
            if (payments.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No payments yet'))),
          ],
          if (tab == 2) ...[
            for (final r in returns) Card(child: ListTile(
              title: Text('Return ${money(r.amount)} • Qty ${r.quantity}'),
              subtitle: Text('Sale ${r.saleId} • Product ${r.productId}'),
            )),
            if (returns.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No returns yet'))),
          ],
          if (tab == 3) ...[
            for (final m in moves) Card(child: ListTile(
              title: Text('${m.type.toUpperCase()} • ${m.quantity}'),
              subtitle: Text('Product ${m.productId}\n${m.date}'), isThreeLine: true,
            )),
            if (moves.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No stock movements yet'))),
          ],
          if (tab == 4) ...[
            for (final s in sales) Card(child: ListTile(
              title: Text('Invoice ${s.id.substring(s.id.length - 6)}'),
              subtitle: Text('${s.date} • ${money(s.total)}'),
              trailing: FilledButton(onPressed: () => receipt(s), child: const Text('View')),
            )),
            if (sales.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No invoices yet'))),
          ],
        ])),
      ]),
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
