import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/business_models.dart';

class BusinessStore {
  BusinessStore(this.prefs);

  final SharedPreferences prefs;

  static const productsKey = 'b360_products_v1';
  static const customersKey = 'b360_customers_v1';
  static const suppliersKey = 'b360_suppliers_v1';
  static const salesKey = 'b360_sales_v1';
  static const purchasesKey = 'b360_purchases_v1';
  static const expensesKey = 'b360_expenses_v1';
  static const paymentsKey = 'b360_payments_v1';
  static const returnsKey = 'b360_returns_v1';
  static const stockMovesKey = 'b360_stock_moves_v1';
  static const safetyKey = 'b360_safety_backup_v2';

  List<Product> get products => _decode(productsKey, Product.fromJson);
  List<Customer> get customers => _decode(customersKey, Customer.fromJson);
  List<Supplier> get suppliers => _decode(suppliersKey, Supplier.fromJson);
  List<Sale> get sales => _decode(salesKey, Sale.fromJson);
  List<Purchase> get purchases => _decode(purchasesKey, Purchase.fromJson);
  List<BusinessExpense> get expenses => _decode(expensesKey, BusinessExpense.fromJson);
  List<Payment> get payments => _decode(paymentsKey, Payment.fromJson);
  List<ReturnRecord> get returns => _decode(returnsKey, ReturnRecord.fromJson);
  List<StockMove> get stockMoves => _decode(stockMovesKey, StockMove.fromJson);

  List<T> _decode<T>(String key, T Function(Map<String, dynamic>) factory) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => factory(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> saveProducts(List<Product> value) => _save(productsKey, value.map((e) => e.toJson()).toList());
  Future<void> saveCustomers(List<Customer> value) => _save(customersKey, value.map((e) => e.toJson()).toList());
  Future<void> saveSuppliers(List<Supplier> value) => _save(suppliersKey, value.map((e) => e.toJson()).toList());
  Future<void> saveSales(List<Sale> value) => _save(salesKey, value.map((e) => e.toJson()).toList());
  Future<void> savePurchases(List<Purchase> value) => _save(purchasesKey, value.map((e) => e.toJson()).toList());
  Future<void> saveExpenses(List<BusinessExpense> value) => _save(expensesKey, value.map((e) => e.toJson()).toList());
  Future<void> savePayments(List<Payment> value) => _save(paymentsKey, value.map((e) => e.toJson()).toList());
  Future<void> saveReturns(List<ReturnRecord> value) => _save(returnsKey, value.map((e) => e.toJson()).toList());
  Future<void> saveStockMoves(List<StockMove> value) => _save(stockMovesKey, value.map((e) => e.toJson()).toList());

  Future<void> _save(String key, List<Map<String, dynamic>> value) async {
    await prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic> snapshot() => {
    'products': products.map((e) => e.toJson()).toList(),
    'customers': customers.map((e) => e.toJson()).toList(),
    'suppliers': suppliers.map((e) => e.toJson()).toList(),
    'sales': sales.map((e) => e.toJson()).toList(),
    'purchases': purchases.map((e) => e.toJson()).toList(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
    'returns': returns.map((e) => e.toJson()).toList(),
    'stockMoves': stockMoves.map((e) => e.toJson()).toList(),
    'counters': {
      'sale': prefs.getInt('counter_sale') ?? 1001,
      'purchase': prefs.getInt('counter_purchase') ?? 2001,
      'return': prefs.getInt('counter_return') ?? 3001,
    },
    'settings': _settingsSnapshot(),
    'version': 4,
  };

  Map<String, dynamic> _settingsSnapshot() => {
    for (final key in _settingKeys) key: prefs.get(key),
  };

  static const _settingKeys = [
    'shop', 'address', 'phone', 'currency', 'invoicePrefix', 'lowStock', 'receiptWidth',
    'theme', 'appBg', 'productBg', 'dashboardBg', 'dashboardCardBg', 'dashboardBorder',
    'dashboardCardColors', 'buttonTheme', 'panelBg', 'dashboardOrder', 'logo', 'logoRemoved',
    'securityMode', 'pinHash', 'patternHash',
  ];

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
    final maps = <String, String>{
      'products': productsKey, 'customers': customersKey, 'suppliers': suppliersKey,
      'sales': salesKey, 'purchases': purchasesKey, 'expenses': expensesKey,
      'payments': paymentsKey, 'returns': returnsKey, 'stockMoves': stockMovesKey,
    };
    for (final entry in maps.entries) {
      await _restoreList(entry.value, data[entry.key]);
    }
    final settings = data['settings'];
    if (settings is Map) {
      for (final key in _settingKeys) {
        final value = settings[key];
        if (value is String) await prefs.setString(key, value);
        else if (value is bool) await prefs.setBool(key, value);
        else if (value is int) await prefs.setInt(key, value);
        else if (value is double) await prefs.setDouble(key, value);
        else if (value is List || value is Map) await prefs.setString(key, jsonEncode(value));
      }
    }
    final counters = data['counters'];
    if (counters is Map) {
      for (final key in ['sale', 'purchase', 'return']) {
        final value = counters[key];
        if (value is num) await prefs.setInt('counter_$key', value.toInt());
      }
    }
  }

  Future<void> _restoreList(String key, dynamic value) async {
    if (value is List) await _save(key, value.map((e) => Map<String, dynamic>.from(e as Map)).toList());
  }

  Future<bool> restoreSafetyBackup() async {
    final raw = prefs.getString(safetyKey);
    if (raw == null || raw.isEmpty) return false;
    await restoreJson(raw);
    return true;
  }
}
