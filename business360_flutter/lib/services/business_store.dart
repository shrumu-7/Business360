import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/business_models.dart';

class BusinessStore {
  BusinessStore(this.prefs);

  final SharedPreferences prefs;

  static const productsKey = 'b360_products_v1';
  static const customersKey = 'b360_customers_v1';
  static const salesKey = 'b360_sales_v1';
  static const expensesKey = 'b360_expenses_v1';
  static const purchasesKey = 'b360_purchases_v1';
  static const safetyKey = 'b360_safety_backup_v1';

  List<Product> get products => _decode(productsKey, Product.fromJson);
  List<Customer> get customers => _decode(customersKey, Customer.fromJson);
  List<Sale> get sales => _decode(salesKey, Sale.fromJson);
  List<BusinessExpense> get expenses =>
      _decode(expensesKey, BusinessExpense.fromJson);
  List<Purchase> get purchases => _decode(purchasesKey, Purchase.fromJson);

  List<T> _decode<T>(
    String key,
    T Function(Map<String, dynamic>) factory,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => factory(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> saveProducts(List<Product> value) =>
      _save(productsKey, value.map((item) => item.toJson()).toList());

  Future<void> saveCustomers(List<Customer> value) =>
      _save(customersKey, value.map((item) => item.toJson()).toList());

  Future<void> saveSales(List<Sale> value) =>
      _save(salesKey, value.map((item) => item.toJson()).toList());

  Future<void> saveExpenses(List<BusinessExpense> value) =>
      _save(expensesKey, value.map((item) => item.toJson()).toList());

  Future<void> savePurchases(List<Purchase> value) =>
      _save(purchasesKey, value.map((item) => item.toJson()).toList());

  Future<void> _save(String key, List<Map<String, dynamic>> value) {
    return prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic> snapshot() {
    return {
      'products': products.map((item) => item.toJson()).toList(),
      'customers': customers.map((item) => item.toJson()).toList(),
      'sales': sales.map((item) => item.toJson()).toList(),
      'expenses': expenses.map((item) => item.toJson()).toList(),
      'purchases': purchases.map((item) => item.toJson()).toList(),
      'settings': {
        'shop': prefs.getString('shop'),
        'address': prefs.getString('address'),
        'phone': prefs.getString('phone'),
        'currency': prefs.getString('currency'),
        'invoicePrefix': prefs.getString('invoicePrefix'),
        'lowStock': prefs.getInt('lowStock'),
        'theme': prefs.getString('theme'),
        'appBg': prefs.getString('appBg'),
        'dashboardBg': prefs.getString('dashboardBg'),
        'dashboardCardBg': prefs.getString('dashboardCardBg'),
        'dashboardBorder': prefs.getString('dashboardBorder'),
        'buttonTheme': prefs.getString('buttonTheme'),
        'logoRemoved': prefs.getBool('logoRemoved'),
        'securityMode': prefs.getString('securityMode'),
      },
      'version': 3,
    };
  }

  Future<String> exportJson() async {
    final text = jsonEncode(snapshot());
    await prefs.setString('b360_last_export', text);
    return text;
  }

  Future<void> saveSafetyBackup() async {
    await prefs.setString(safetyKey, jsonEncode(snapshot()));
  }

  Future<void> restoreJson(String text) async {
    final data = Map<String, dynamic>.from(jsonDecode(text) as Map);
    await _restoreList(productsKey, data['products']);
    await _restoreList(customersKey, data['customers']);
    await _restoreList(salesKey, data['sales']);
    await _restoreList(expensesKey, data['expenses']);
    await _restoreList(purchasesKey, data['purchases']);

    final settings = data['settings'];
    if (settings is Map) {
      await _restoreString('shop', settings['shop']);
      await _restoreString('address', settings['address']);
      await _restoreString('phone', settings['phone']);
      await _restoreString('currency', settings['currency']);
      await _restoreString('invoicePrefix', settings['invoicePrefix']);
      await _restoreInt('lowStock', settings['lowStock']);
      await _restoreString('theme', settings['theme']);
      await _restoreString('appBg', settings['appBg']);
      await _restoreString('dashboardBg', settings['dashboardBg']);
      await _restoreString('dashboardCardBg', settings['dashboardCardBg']);
      await _restoreString('dashboardBorder', settings['dashboardBorder']);
      await _restoreString('buttonTheme', settings['buttonTheme']);
      await _restoreBool('logoRemoved', settings['logoRemoved']);
      await _restoreString('securityMode', settings['securityMode']);
    }
  }

  Future<void> _restoreList(String key, dynamic value) async {
    if (value is! List) return;
    final list = value
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    await _save(key, list);
  }

  Future<void> _restoreString(String key, dynamic value) async {
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _restoreInt(String key, dynamic value) async {
    if (value is int) await prefs.setInt(key, value);
  }

  Future<void> _restoreBool(String key, dynamic value) async {
    if (value is bool) await prefs.setBool(key, value);
  }

  Future<bool> restoreSafetyBackup() async {
    final raw = prefs.getString(safetyKey);
    if (raw == null || raw.isEmpty) return false;
    await restoreJson(raw);
    return true;
  }
}
