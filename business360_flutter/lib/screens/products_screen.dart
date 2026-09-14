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
  @override void initState(){super.initState(); items=widget.store.products;}
  Future<void> addOrEdit([Product? old]) async {
    final name=TextEditingController(text: old?.name??''); final price=TextEditingController(text: old?.price.toString()??''); final stock=TextEditingController(text: old?.stock.toString()??'');
    final result=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text(old==null?'Add Product':'Edit Product'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Product name')),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Selling price')),TextField(controller:stock,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Stock'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Save'))]));
    if(result!=true||name.text.trim().isEmpty)return;
    setState((){if(old==null){items.add(Product(id:DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),price:double.tryParse(price.text)??0,stock:double.tryParse(stock.text)??0));}else{old.name=name.text.trim();old.price=double.tryParse(price.text)??0;old.stock=double.tryParse(stock.text)??0;}}); await widget.store.saveProducts(items);
  }
  Future<void> remove(Product p) async {setState(()=>items.remove(p));await widget.store.saveProducts(items);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Products & Stock')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>addOrEdit(),icon:const Icon(Icons.add),label:const Text('Product')),body:items.isEmpty?const Center(child:Text('No products yet')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i){final p=items[i];return Card(child:ListTile(title:Text(p.name),subtitle:Text('Stock: ${p.stock}  •  Price: ৳${p.price.toStringAsFixed(2)}'),trailing:Wrap(children:[IconButton(onPressed:()=>addOrEdit(p),icon:const Icon(Icons.edit)),IconButton(onPressed:()=>remove(p),icon:const Icon(Icons.delete_outline))]));}));
}
