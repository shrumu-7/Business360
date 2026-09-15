import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_models.dart';

class BusinessStore {
  BusinessStore(this.prefs);
  final SharedPreferences prefs;
  static const productsKey='b360_products_v1';
  static const customersKey='b360_customers_v1';
  static const salesKey='b360_sales_v1';
  static const expensesKey='b360_expenses_v1';
  static const purchasesKey='b360_purchases_v1';
  static const safetyKey='b360_safety_backup_v1';
  List<Product> get products=>_decode(productsKey,Product.fromJson);
  List<Customer> get customers=>_decode(customersKey,Customer.fromJson);
  List<Sale> get sales=>_decode(salesKey,Sale.fromJson);
  List<BusinessExpense> get expenses=>_decode(expensesKey,BusinessExpense.fromJson);
  List<Purchase> get purchases=>_decode(purchasesKey,Purchase.fromJson);
  List<T> _decode<T>(String key,T Function(Map<String,dynamic>) factory){final raw=prefs.getString(key);if(raw==null||raw.isEmpty)return [];try{return(jsonDecode(raw) as List).map((e)=>factory(Map<String,dynamic>.from(e))).toList();}catch(_){return [];}}
  Future<void> saveProducts(List<Product> v)=>_save(productsKey,v.map((e)=>e.toJson()).toList());
  Future<void> saveCustomers(List<Customer> v)=>_save(customersKey,v.map((e)=>e.toJson()).toList());
  Future<void> saveSales(List<Sale> v)=>_save(salesKey,v.map((e)=>e.toJson()).toList());
  Future<void> saveExpenses(List<BusinessExpense> v)=>_save(expensesKey,v.map((e)=>e.toJson()).toList());
  Future<void> savePurchases(List<Purchase> v)=>_save(purchasesKey,v.map((e)=>e.toJson()).toList());
  Future<void> _save(String key,List<Map<String,dynamic>> value)=>prefs.setString(key,jsonEncode(value));
  Map<String,dynamic> snapshot()=>{'products':products.map((e)=>e.toJson()).toList(),'customers':customers.map((e)=>e.toJson()).toList(),'sales':sales.map((e)=>e.toJson()).toList(),'expenses':expenses.map((e)=>e.toJson()).toList(),'purchases':purchases.map((e)=>e.toJson()).toList(),'version':2};
  Future<String> exportJson() async {final text=jsonEncode(snapshot());await prefs.setString('b360_last_export',text);return text;}
  Future<void> saveSafetyBackup() async {await prefs.setString(safetyKey,jsonEncode(snapshot()));}
  Future<void> restoreJson(String text) async {final m=Map<String,dynamic>.from(jsonDecode(text));await _save(productsKey,((m['products'] as List?)??[]).map((e)=>Map<String,dynamic>.from(e)).toList());await _save(customersKey,((m['customers'] as List?)??[]).map((e)=>Map<String,dynamic>.from(e)).toList());await _save(salesKey,((m['sales'] as List?)??[]).map((e)=>Map<String,dynamic>.from(e)).toList());await _save(expensesKey,((m['expenses'] as List?)??[]).map((e)=>Map<String,dynamic>.from(e)).toList());await _save(purchasesKey,((m['purchases'] as List?)??[]).map((e)=>Map<String,dynamic>.from(e)).toList());}
  Future<bool> restoreSafetyBackup() async {final raw=prefs.getString(safetyKey);if(raw==null)return false;await restoreJson(raw);return true;}
}
