import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/about_screen.dart';
import 'screens/advanced_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';
import 'services/business_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(Business360App(prefs: prefs));
}

class Business360App extends StatefulWidget {
  const Business360App({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override State<Business360App> createState() => _Business360AppState();
}

class _Business360AppState extends State<Business360App> {
  late final BusinessStore store;
  ThemeMode mode = ThemeMode.light;
  String appBg = 'blueWhite';
  String theme = 'purple';
  bool locked = false;

  @override
  void initState() {
    super.initState();
    store = BusinessStore(widget.prefs);
    _load();
  }

  void _load() {
    mode = widget.prefs.getBool('dark_mode') == true ? ThemeMode.dark : ThemeMode.light;
    appBg = widget.prefs.getString('appBg') ?? 'blueWhite';
    theme = widget.prefs.getString('theme') ?? 'purple';
    locked = widget.prefs.getString('securityMode') != null &&
        widget.prefs.getString('securityMode') != 'none' &&
        ((widget.prefs.getString('pinHash') ?? '').isNotEmpty ||
            (widget.prefs.getString('patternHash') ?? '').isNotEmpty);
  }

  void refresh() => setState(_load);

  void toggleTheme() {
    setState(() => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
    widget.prefs.setBool('dark_mode', mode == ThemeMode.dark);
  }

  Color background() {
    switch (appBg) {
      case 'midnight': return const Color(0xFF0E1420);
      case 'slate': return const Color(0xFF202735);
      case 'cream': return const Color(0xFFFFF8EA);
      default: return const Color(0xFFF4F7FC);
    }
  }

  Color seedColor() {
    switch (theme) {
      case 'blue': return const Color(0xFF087EA4);
      case 'green': return const Color(0xFF15803D);
      case 'dark': return const Color(0xFF686FF0);
      default: return const Color(0xFF6C57F5);
    }
  }

  ThemeData appTheme(Brightness b) => ThemeData(
    useMaterial3: true,
    brightness: b,
    colorSchemeSeed: seedColor(),
    scaffoldBackgroundColor: background(),
    canvasColor: background(),
    appBarTheme: AppBarTheme(backgroundColor: background(), surfaceTintColor: Colors.transparent),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Business360',
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    themeMode: mode,
    home: locked
        ? LockScreen(prefs: widget.prefs, onUnlocked: () => setState(() => locked = false))
        : HomeScreen(prefs: widget.prefs, store: store, dark: mode == ThemeMode.dark, onTheme: toggleTheme, onSettingsChanged: refresh),
  );
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.prefs, required this.onUnlocked});
  final SharedPreferences prefs;
  final VoidCallback onUnlocked;
  @override State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final input = TextEditingController();
  String error = '';
  String hash(String s) => sha256.convert(utf8.encode(s.trim())).toString();
  void unlock() {
    final mode = widget.prefs.getString('securityMode') ?? 'none';
    final expected = mode == 'pin' ? widget.prefs.getString('pinHash') : widget.prefs.getString('patternHash');
    if (expected != null && expected.isNotEmpty && hash(input.text) == expected) {
      widget.onUnlocked();
    } else {
      setState(() => error = 'ভুল কোড। আবার চেষ্টা করুন।');
      input.clear();
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: Card(margin: const EdgeInsets.all(24), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_rounded, size: 54), const SizedBox(height: 12),
      const Text('Business360 Locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('আপনার PIN / Pattern code দিন'), const SizedBox(height: 20),
      TextField(controller: input, obscureText: true, autofocus: true, onSubmitted: (_) => unlock(), decoration: InputDecoration(labelText: 'Security code', errorText: error.isEmpty ? null : error, border: const OutlineInputBorder())),
      const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: unlock, icon: const Icon(Icons.lock_open), label: const Text('Unlock'))),
    ]))),),
  );
  @override void dispose() { input.dispose(); super.dispose(); }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.prefs, required this.dark, required this.onTheme, required this.onSettingsChanged});
  final BusinessStore store; final SharedPreferences prefs; final bool dark; final VoidCallback onTheme; final VoidCallback onSettingsChanged;
  static const pages = ['Dashboard','Sales / POS','Products & Stock','Customers','Reports','Purchases & Expenses','Business Tools','About Developer'];
  static const icons = [Icons.dashboard,Icons.point_of_sale,Icons.inventory_2,Icons.people,Icons.bar_chart,Icons.account_balance_wallet,Icons.business_center,Icons.info];
  Widget page(int index) {
    switch (index) {
      case 1: return SalesScreen(store: store);
      case 2: return ProductsScreen(store: store);
      case 3: return CustomersScreen(store: store);
      case 4: return ReportsScreen(store: store);
      case 5: return FinanceScreen(store: store);
      case 6: return AdvancedScreen(store: store);
      case 7: return const AboutScreen();
      default: return DashboardPage(store: store, prefs: prefs);
    }
  }
  void openSettings(BuildContext context) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: .94, child: SettingsScreen(prefs: prefs, store: store, onChanged: onSettingsChanged)));
  @override Widget build(BuildContext context) {
    final shop = prefs.getString('shop') ?? 'আমার দোকান';
    return DefaultTabController(length: 1, child: Scaffold(
      appBar: AppBar(title: Text(shop), actions: [IconButton(onPressed: onTheme, icon: Icon(dark ? Icons.light_mode : Icons.dark_mode)), IconButton(onPressed: () => openSettings(context), icon: const Icon(Icons.settings))]),
      drawer: Drawer(child: SafeArea(child: ListView(padding: const EdgeInsets.all(12), children: [Padding(padding: const EdgeInsets.all(16), child: Text(shop, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), for (var i = 0; i < pages.length; i++) ListTile(leading: Icon(icons[i]), title: Text(pages[i]), onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => page(i))); }), const Divider(), ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () { Navigator.pop(context); openSettings(context); })]))),
      body: Container(color: Theme.of(context).scaffoldBackgroundColor, child: SafeArea(child: DashboardPage(store: store, prefs: prefs))),
      bottomNavigationBar: NavigationBar(selectedIndex: 0, onDestinationSelected: (i) { if (i == 0) return; Navigator.of(context).push(MaterialPageRoute(builder: (_) => page(i))); }, destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'), NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'), NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'), NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'), NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports')]),
    ));
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store, required this.prefs});
  final BusinessStore store; final SharedPreferences prefs;
  Color dashboardBackground() { switch (prefs.getString('dashboardBg') ?? 'midnight') { case 'blue': return const Color(0xFF0B3B60); case 'plain': return Colors.transparent; default: return const Color(0xFF151B2B); } }
  Color namedColor(String name) { const m = {'emerald':Color(0xFF157F5B),'ruby':Color(0xFFB94A48),'blue':Color(0xFF2D5BBA),'pink':Color(0xFFB34D91),'orange':Color(0xFFC56B1E),'turquoise':Color(0xFF176F8B),'purple':Color(0xFF7A4FB2),'indigo':Color(0xFF4354A8),'cyan':Color(0xFF336B70),'gold':Color(0xFF8B6A22)}; return m[name] ?? const Color(0xFF52607A); }
  @override Widget build(BuildContext context) {
    final products = store.products, customers = store.customers, sales = store.sales;
    final currency = prefs.getString('currency') ?? '৳';
    final totalSales = sales.fold<double>(0, (s, x) => s + x.total), profit = sales.fold<double>(0, (s, x) => s + x.profit), due = customers.fold<double>(0, (s, x) => s + x.due), stock = products.fold<double>(0, (s, x) => s + x.cost * x.stock), expenses = store.expenses.fold<double>(0, (s, x) => s + x.amount), purchases = store.purchases.fold<double>(0, (s, x) => s + x.amount);
    final today = DateTime.now();
    final todaySales = sales.where((x) => x.date.year == today.year && x.date.month == today.month && x.date.day == today.day).fold<double>(0, (s, x) => s + x.total);
    final low = products.where((x) => x.stock <= (prefs.getInt('lowStock') ?? 5)).length;
    final values = <String, (String,String,IconData)>{
      'income': ('Income', '$currency${totalSales.toStringAsFixed(2)}', Icons.payments), 'expense': ('Expense', '$currency${expenses.toStringAsFixed(2)}', Icons.money_off), 'products': ('Products','${products.length}',Icons.inventory_2), 'parties': ('Parties','${customers.length}',Icons.people), 'sales': ('Sales','$currency${todaySales.toStringAsFixed(2)}',Icons.point_of_sale), 'purchase': ('Purchase','$currency${purchases.toStringAsFixed(2)}',Icons.shopping_cart), 'dues': ('Dues','$currency${due.toStringAsFixed(2)}',Icons.account_balance_wallet), 'debt': ('Receivable','$currency${due.toStringAsFixed(2)}',Icons.request_quote), 'stock': ('Low Stock','$low',Icons.warning_amber), 'stockValue': ('Stock Value','$currency${stock.toStringAsFixed(2)}',Icons.warehouse), 'profit': ('Profit','$currency${profit.toStringAsFixed(2)}',Icons.trending_up),
    };
    final defaultOrder = ['income','expense','products','parties','sales','purchase','dues','debt','stock','stockValue','profit'];
    final savedOrder = prefs.getString('dashboardOrder'); List<String> order = defaultOrder;
    if (savedOrder != null) { try { final parsed = List<String>.from(jsonDecode(savedOrder)); final valid = parsed.where(values.containsKey).toList(); if (valid.length == values.length) order = valid; } catch (_) {} }
    final colorsRaw = prefs.getString('dashboardCardColors'); Map<String,String> cardColors = {};
    if (colorsRaw != null) { try { cardColors = Map<String,String>.from(jsonDecode(colorsRaw)); } catch (_) {} }
    final style = prefs.getString('dashboardCardBg') ?? 'gradient', border = prefs.getString('dashboardBorder') ?? 'glow';
    final bg = dashboardBackground();
    return Container(color: bg, child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: prefs.getString('panelBg') == 'obsidian' ? const Color(0xFF202634) : null, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(prefs.getString('shop') ?? 'আমার দোকান', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text((prefs.getString('address') ?? '').isEmpty ? 'Smart Business Management' : prefs.getString('address')!), if ((prefs.getString('phone') ?? '').isNotEmpty) Text(prefs.getString('phone')!)]))),
      const SizedBox(height: 12), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: order.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2), itemBuilder: (context, i) { final key = order[i], card = values[key]!; final base = namedColor(cardColors[key] ?? 'blue'); final bgc = style == 'glass' ? Colors.white.withValues(alpha: .14) : style == 'solid' ? base : Color.lerp(base, Colors.black, .12)!; final side = border == 'none' ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: border == 'glow' ? .35 : .15), width: border == 'glow' ? 1.5 : 1); return Card(color: bgc, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: side), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(card.$3, size: 30), const SizedBox(height: 10), Text(card.$1), const SizedBox(height: 4), Text(card.$2, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))]))); }),
    ]));
  }
}
