import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/business_store.dart';
import 'screens/customers_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';

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
  int index = 0;

  @override void initState() { super.initState(); store = BusinessStore(widget.prefs); _load(); }
  void _load() { mode = widget.prefs.getBool('dark_mode') == true ? ThemeMode.dark : ThemeMode.light; appBg = widget.prefs.getString('appBg') ?? 'blueWhite'; theme = widget.prefs.getString('theme') ?? 'purple'; }
  void refresh() => setState(_load);
  void toggleTheme() { setState(() => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light); widget.prefs.setBool('dark_mode', mode == ThemeMode.dark); }

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
  ThemeData _theme(Brightness brightness) => ThemeData(useMaterial3: true, brightness: brightness, colorSchemeSeed: seedColor(), scaffoldBackgroundColor: background(), canvasColor: background(), appBarTheme: AppBarTheme(backgroundColor: background(), surfaceTintColor: Colors.transparent));

  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Business360', theme: _theme(Brightness.light), darkTheme: _theme(Brightness.dark), themeMode: mode, home: HomeScreen(index: index, store: store, prefs: widget.prefs, dark: mode == ThemeMode.dark, onIndexChanged: (v) => setState(() => index = v), onTheme: toggleTheme, onSettingsChanged: refresh));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.index, required this.store, required this.prefs, required this.dark, required this.onIndexChanged, required this.onTheme, required this.onSettingsChanged});
  final int index; final BusinessStore store; final SharedPreferences prefs; final bool dark; final ValueChanged<int> onIndexChanged; final VoidCallback onTheme; final VoidCallback onSettingsChanged;
  static const pages = ['Dashboard', 'Sales / POS', 'Products & Stock', 'Customers', 'Reports', 'Purchases & Expenses'];
  static const icons = [Icons.dashboard, Icons.point_of_sale, Icons.inventory_2, Icons.people, Icons.bar_chart, Icons.account_balance_wallet];
  Widget page() { switch (index) { case 1: return SalesScreen(store: store); case 2: return ProductsScreen(store: store); case 3: return CustomersScreen(store: store); case 4: return ReportsScreen(store: store); case 5: return FinanceScreen(store: store); default: return DashboardPage(store: store, prefs: prefs); } }
  void openSettings(BuildContext context) { showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: .94, child: SettingsScreen(prefs: prefs, store: store, onChanged: onSettingsChanged))); }

  @override Widget build(BuildContext context) {
    final selected = index.clamp(0, 4); final shop = prefs.getString('shop') ?? 'আমার দোকান';
    return Scaffold(
      appBar: AppBar(title: Text(index < pages.length ? pages[index] : shop), actions: [IconButton(onPressed: onTheme, icon: Icon(dark ? Icons.light_mode : Icons.dark_mode)), IconButton(onPressed: () => openSettings(context), icon: const Icon(Icons.settings))]),
      drawer: Drawer(child: SafeArea(child: ListView(padding: const EdgeInsets.all(12), children: [Padding(padding: const EdgeInsets.all(16), child: Text(shop, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), for (var i = 0; i < pages.length; i++) ListTile(leading: Icon(icons[i]), title: Text(pages[i]), selected: index == i, onTap: () { Navigator.pop(context); onIndexChanged(i); }), const Divider(), ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () { Navigator.pop(context); openSettings(context); })]))),
      body: Container(color: Theme.of(context).scaffoldBackgroundColor, child: SafeArea(child: page())),
      bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: onIndexChanged, destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'), NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'), NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'), NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'), NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports')]),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store, required this.prefs});
  final BusinessStore store; final SharedPreferences prefs;
  Color dashboardBackground() { switch (prefs.getString('dashboardBg') ?? 'midnight') { case 'blue': return const Color(0xFF0B3B60); case 'plain': return Colors.transparent; default: return const Color(0xFF151B2B); } }
  Color cardColor(int i) { const colors = [Color(0xFF157F5B), Color(0xFF2D5BBA), Color(0xFF7A4FB2), Color(0xFFB94A48), Color(0xFF176F8B), Color(0xFF8B6A22), Color(0xFF7A3F88), Color(0xFF336B70)]; return colors[i % colors.length]; }

  @override Widget build(BuildContext context) {
    final products = store.products, customers = store.customers, sales = store.sales; final currency = prefs.getString('currency') ?? '৳';
    final totalSales = sales.fold<double>(0, (s, x) => s + x.total), profit = sales.fold<double>(0, (s, x) => s + x.profit), due = customers.fold<double>(0, (s, x) => s + x.due), stock = products.fold<double>(0, (s, x) => s + x.cost * x.stock), expenses = store.expenses.fold<double>(0, (s, x) => s + x.amount), purchases = store.purchases.fold<double>(0, (s, x) => s + x.amount);
    final cards = [('Sales', '$currency${totalSales.toStringAsFixed(2)}', Icons.point_of_sale), ('Profit', '$currency${profit.toStringAsFixed(2)}', Icons.trending_up), ('Products', '${products.length}', Icons.inventory_2), ('Customers', '${customers.length}', Icons.people), ('Due', '$currency${due.toStringAsFixed(2)}', Icons.account_balance_wallet), ('Stock value', '$currency${stock.toStringAsFixed(2)}', Icons.warehouse), ('Expenses', '$currency${expenses.toStringAsFixed(2)}', Icons.money_off), ('Purchases', '$currency${purchases.toStringAsFixed(2)}', Icons.shopping_cart)];
    final dashboardBg = dashboardBackground(), cardStyle = prefs.getString('dashboardCardBg') ?? 'gradient', border = prefs.getString('dashboardBorder') ?? 'glow';
    return Container(color: dashboardBg, child: ListView(padding: const EdgeInsets.all(16), children: [Card(color: cardStyle == 'glass' ? Colors.white.withValues(alpha: .12) : null, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(prefs.getString('shop') ?? 'আমার দোকান', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text((prefs.getString('address') ?? '').isEmpty ? 'Smart Business Management' : prefs.getString('address')!), if ((prefs.getString('phone') ?? '').isNotEmpty) Text(prefs.getString('phone')!)]))), const SizedBox(height: 12), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: cards.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2), itemBuilder: (context, i) { final c = cards[i]; final bg = cardStyle == 'glass' ? Colors.white.withValues(alpha: .14) : cardColor(i); return Card(color: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: border == 'none' ? BorderSide.none : BorderSide(color: border == 'glow' ? Colors.white.withValues(alpha: .35) : Colors.white.withValues(alpha: .15), width: border == 'glow' ? 1.5 : 1)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(c.$3, size: 30), const SizedBox(height: 10), Text(c.$1), const SizedBox(height: 4), Text(c.$2, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))]))); })]));
  }
}
