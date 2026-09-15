import 'package:flutter/material.dart';
import '../models/business_models.dart';
import '../services/business_store.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.store});
  final BusinessStore store;
  @override State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late List<Customer> items;
  @override void initState() { super.initState(); items = widget.store.customers; }

  Future<void> addOrEdit([Customer? old]) async {
    final name = TextEditingController(text: old?.name ?? '');
    final phone = TextEditingController(text: old?.phone ?? '');
    final address = TextEditingController(text: old?.address ?? '');
    final due = TextEditingController(text: old?.due.toString() ?? '');
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(old == null ? 'Add Customer' : 'Edit Customer'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
        TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
        TextField(controller: due, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Due')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save'))],
    ));
    if (ok != true || name.text.trim().isEmpty) return;
    final customer = old ?? Customer(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name.text.trim(), phone: '', due: 0);
    customer.name = name.text.trim(); customer.phone = phone.text.trim(); customer.address = address.text.trim(); customer.due = double.tryParse(due.text) ?? 0;
    setState(() { if (old == null) items.add(customer); });
    await widget.store.saveCustomers(items);
  }

  Future<void> remove(Customer customer) async { setState(() => items.remove(customer)); await widget.store.saveCustomers(items); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => addOrEdit(), icon: const Icon(Icons.person_add), label: const Text('Customer')),
      body: items.isEmpty ? const Center(child: Text('No customers yet')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (context, i) {
        final c = items[i];
        return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(c.name), subtitle: Text('${c.phone.isEmpty ? 'No phone' : c.phone} • ${c.address.isEmpty ? 'No address' : c.address} • Due: ৳${c.due.toStringAsFixed(2)}'), trailing: Wrap(children: [IconButton(onPressed: () => addOrEdit(c), icon: const Icon(Icons.edit)), IconButton(onPressed: () => remove(c), icon: const Icon(Icons.delete_outline))])));
      }),
    );
  }
}
