import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/business_store.dart';
import 'screens/customers_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/sales_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(Business360App(prefs: prefs));
}

class Business360App extends StatefulWidget {
  const Business360App({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<Business360App> createState() => _Business360AppState();
}

class _Business360AppState extends State<Business360App> {
  int index = 0;
  late final BusinessStore store;
  ThemeMode mode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    store = BusinessStore(widget.prefs);
    mode = widget.prefs.getBool('dark_mode') == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  void toggleTheme() {
    setState(() {
      mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    widget.prefs.setBool('dark_mode', mode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Business360',
      themeMode: mode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C57F5),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8B7CFF),
        brightness: Brightness.dark,
      ),
      home: HomeScreen(
        index: index,
        onIndexChanged: (value) => setState(() => index = value),
        onTheme: toggleTheme,
        dark: mode == ThemeMode.dark,
        store: store,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.index,
    required this.onIndexChanged,
    required this.onTheme,
    required this.dark,
    required this.store,
  });

  final int index;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onTheme;
  final bool dark;
  final BusinessStore store;

  static const pages = <String>[
    'Dashboard',
    'Sales / POS',
    'Products & Stock',
    'Customers',
    'Reports',
    'Purchases & Expenses',
  ];

  Widget page() {
    switch (index) {
      case 1:
        return SalesScreen(store: store);
      case 2:
        return ProductsScreen(store: store);
      case 3:
        return CustomersScreen(store: store);
      case 4:
        return ReportsScreen(store: store);
      case 5:
        return FinanceScreen(store: store);
      default:
        return DashboardPage(store: store);
    }
  }

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      Icons.dashboard,
      Icons.point_of_sale,
      Icons.inventory_2,
      Icons.people,
      Icons.bar_chart,
      Icons.account_balance_wallet,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pages[index]),
        actions: [
          IconButton(
            onPressed: onTheme,
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: dark ? 'Light mode' : 'Dark mode',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Business360',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              for (var i = 0; i < pages.length; i++)
                ListTile(
                  leading: Icon(icons[i]),
                  title: Text(pages[i]),
                  selected: index == i,
                  onTap: () {
                    Navigator.pop(context);
                    onIndexChanged(i);
                  },
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: page()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index > 4 ? 0 : index,
        onDestinationSelected: onIndexChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store});
  final BusinessStore store;

  @override
  Widget build(BuildContext context) {
    final products = store.products;
    final customers = store.customers;
    final sales = store.sales;
    final totalSales = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final profit = sales.fold<double>(0, (sum, sale) => sum + sale.profit);
    final due = customers.fold<double>(0, (sum, customer) => sum + customer.due);
    final stockValue = products.fold<double>(
      0,
      (sum, product) => sum + product.cost * product.stock,
    );
    final expenses = store.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final purchases = store.purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.amount,
    );

    final cards = <({String title, String value, IconData icon})>[
      (title: 'Sales', value: '৳${totalSales.toStringAsFixed(2)}', icon: Icons.point_of_sale),
      (title: 'Profit', value: '৳${profit.toStringAsFixed(2)}', icon: Icons.trending_up),
      (title: 'Products', value: '${products.length}', icon: Icons.inventory_2),
      (title: 'Customers', value: '${customers.length}', icon: Icons.people),
      (title: 'Due', value: '৳${due.toStringAsFixed(2)}', icon: Icons.account_balance_wallet),
      (title: 'Stock value', value: '৳${stockValue.toStringAsFixed(2)}', icon: Icons.warehouse),
      (title: 'Expenses', value: '৳${expenses.toStringAsFixed(2)}', icon: Icons.money_off),
      (title: 'Purchases', value: '৳${purchases.toStringAsFixed(2)}', icon: Icons.shopping_cart),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Business360',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text('Smart Business Management'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, i) {
            final card = cards[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(card.icon, size: 30),
                    const SizedBox(height: 10),
                    Text(card.title),
                    const SizedBox(height: 4),
                    Text(
                      card.value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
