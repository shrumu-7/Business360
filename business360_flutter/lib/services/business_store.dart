import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_models.dart';

class BusinessStore {
  BusinessStore(this.prefs);
  final SharedPreferences prefs;
  static const productsKey = 'b360_products_v1';
  static const customersKey = 'b360_customers_v1';
  static const salesKey = 'b360_sales_v1';

  List<Product> get products => _decode(productsKey, Product.fromJson);
  List<Customer> get customers => _decode(customersKey, Customer.fromJson);
  List<Sale> get sales => _decode(salesKey, Sale.fromJson);

  List<T> _decode<T>(String key, T Function(Map<String, dynamic>) factory) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => factory(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return []; }
  }

  Future<void> saveProducts(List<Product> value) => _save(productsKey, value.map((e) => e.toJson()).toList());
  Future<void> saveCustomers(List<Customer> value) => _save(customersKey, value.map((e) => e.toJson()).toList());
  Future<void> saveSales(List<Sale> value) => _save(salesKey, value.map((e) => e.toJson()).toList());

  Future<void> _save(String key, List<Map<String, dynamic>> value) => prefs.setString(key, jsonEncode(value));
}
