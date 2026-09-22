import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/business_models.dart';
import '../services/business_store.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.store});
  final BusinessStore store;
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}


class _ImportedProduct {
  _ImportedProduct({required this.name, required this.cost, required this.price, required this.stock, this.unit = 'pcs'});
  String name;
  double cost;
  double price;
  double stock;
  String unit;
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

  Future<ImageSource?> _chooseImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            subtitle: const Text('Capture the previous product list'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose photo / screenshot'),
            subtitle: const Text('Select an existing product-list image'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ]),
      ),
    );
  }

  Future<void> smartStockImport() async {
    final source = await _chooseImageSource();
    if (source == null) return;
    final image = await ImagePicker().pickImage(source: source, imageQuality: 100);
    if (image == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 18),
          Expanded(child: Text('Reading product list…')),
        ]),
      ),
    );

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(image.path));
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final rows = _parseOcr(result.text);
      if (rows.isEmpty) {
        await _showOcrHelp(result.text);
      } else {
        await _showImportPreview(rows);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not read the image: ' + e.toString())));
      }
    } finally {
      await recognizer.close();
    }
  }

  List<_ImportedProduct> _parseOcr(String text) {
    final rows = <_ImportedProduct>[];
    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;
      final matches = RegExp(r'(?<![A-Za-z])\d+(?:[.,]\d+)?').allMatches(line).toList();
      if (matches.length < 3) continue;
      final values = matches
          .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')))
          .whereType<double>()
          .toList();
      if (values.length < 3) continue;
      final first = matches.first;
      final name = line.substring(0, first.start).replaceAll(RegExp(r'[-|:]+
  @override Widget build(BuildContext context) {
    final threshold = widget.store.prefs.getInt('lowStock') ?? 5;
    final currency = widget.store.prefs.getString('currency') ?? '৳';
    final categories = ['All', ...{for (final p in items) if (p.category.trim().isNotEmpty) p.category.trim()}];
    final shown = filter == 'All' ? items : items.where((p) => p.category.trim() == filter).toList();
    if (!categories.contains(filter)) filter = 'All';
    return Scaffold(
      appBar: AppBar(title: const Text('Products & Stock'), actions: [IconButton(tooltip: 'Smart Stock Import', onPressed: smartStockImport, icon: const Icon(Icons.document_scanner_outlined))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => addOrEdit(), icon: const Icon(Icons.add), label: const Text('Product')),
      body: Column(children: [
        if (categories.length > 1) SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [for (final c in categories) Padding(padding: const EdgeInsets.only(right: 8, top: 8), child: ChoiceChip(label: Text(c), selected: filter == c, onSelected: (_) => setState(() => filter = c)))])),
        Expanded(child: shown.isEmpty ? const Center(child: Text('No products yet')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: shown.length, itemBuilder: (context, i) {
          final p = shown[i]; final low = p.stock <= threshold;
          return Card(child: ListTile(
            leading: CircleAvatar(child: Icon(low ? Icons.warning_amber : Icons.inventory_2)),
            title: Text(p.name),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.category.isEmpty ? 'No category' : p.category), Text('Purchase: $currency${p.cost.toStringAsFixed(2)}   •   Selling: $currency${p.price.toStringAsFixed(2)}'), Text('Stock: ${p.stock} ${p.unit}${low ? '   •   LOW STOCK' : ''}')]),
            trailing: Wrap(children: [IconButton(onPressed: () => addOrEdit(p), icon: const Icon(Icons.edit)), IconButton(onPressed: () => remove(p), icon: const Icon(Icons.delete_outline))]),
          ));
        })),
      ]),
    );
  }
}
), '').trim();
      if (name.length < 2 || _looksLikeHeader(name)) continue;
      rows.add(_ImportedProduct(
        name: name,
        cost: values[values.length - 3],
        price: values[values.length - 2],
        stock: values[values.length - 1],
      ));
    }
    return rows;
  }

  bool _looksLikeHeader(String value) {
    final v = value.toLowerCase();
    return v.contains('product') || v.contains('name') || v.contains('price') ||
        v.contains('stock') || v.contains('quantity') || v.contains('item');
  }

  Future<void> _showOcrHelp(String rawText) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No product rows detected'),
        content: Text(rawText.trim().isEmpty
            ? 'No readable text was found. Please use a clearer screenshot/photo.'
            : 'The text was read, but product rows could not be identified. Use a clear table screenshot where each row contains product name, purchase price, selling price and stock.'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _showImportPreview(List<_ImportedProduct> rows) async {
    final controllers = <List<TextEditingController>>[];
    for (final row in rows) {
      controllers.add([
        TextEditingController(text: row.name),
        TextEditingController(text: _number(row.cost)),
        TextEditingController(text: _number(row.price)),
        TextEditingController(text: _number(row.stock)),
        TextEditingController(text: row.unit),
      ]);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Review ' + rows.length.toString() + ' products'),
        content: SizedBox(
          width: 560,
          height: MediaQuery.sizeOf(context).height * .62,
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final c = controllers[index];
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Product ' + (index + 1).toString(), style: Theme.of(context).textTheme.titleSmall),
                TextField(controller: c[0], decoration: const InputDecoration(labelText: 'Product name')),
                Row(children: [
                  Expanded(child: TextField(controller: c[1], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: c[2], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: c[3], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Stock'))),
                ]),
                TextField(controller: c[4], decoration: const InputDecoration(labelText: 'Unit')),
              ]);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (final list in controllers) { for (final c in list) { c.dispose(); } }
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final edited = <_ImportedProduct>[];
              for (final c in controllers) {
                final name = c[0].text.trim();
                if (name.isEmpty) continue;
                edited.add(_ImportedProduct(
                  name: name,
                  cost: double.tryParse(c[1].text.trim()) ?? 0,
                  price: double.tryParse(c[2].text.trim()) ?? 0,
                  stock: double.tryParse(c[3].text.trim()) ?? 0,
                  unit: c[4].text.trim().isEmpty ? 'pcs' : c[4].text.trim(),
                ));
              }
              for (final list in controllers) { for (final c in list) { c.dispose(); } }
              Navigator.pop(dialogContext);
              await _saveImportedProducts(edited);
            },
            child: const Text('Confirm & Add to Stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImportedProducts(List<_ImportedProduct> imported) async {
    if (imported.isEmpty) return;
    final current = [...items];
    var added = 0;
    var merged = 0;

    for (final row in imported) {
      final key = _normalize(row.name);
      Product? existing;
      for (final product in current) {
        if (_normalize(product.name) == key) { existing = product; break; }
      }
      if (existing != null) {
        existing.stock += row.stock;
        if (row.cost > 0) existing.cost = row.cost;
        if (row.price > 0) existing.price = row.price;
        if (row.unit.trim().isNotEmpty) existing.unit = row.unit.trim();
        merged++;
      } else {
        current.add(Product(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: row.name,
          price: row.price,
          cost: row.cost,
          stock: row.stock,
          unit: row.unit,
        ));
        added++;
      }
    }

    setState(() => items = current);
    await widget.store.saveProducts(current);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ' + added.toString() + ' new product(s), merged ' + merged.toString() + ' existing product(s).')),
      );
    }
  }

  String _normalize(String value) => value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

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
