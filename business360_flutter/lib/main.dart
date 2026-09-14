import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
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
  ThemeMode mode = ThemeMode.light;
  @override
  void initState() { super.initState(); mode = widget.prefs.getBool('dark_mode') == true ? ThemeMode.dark : ThemeMode.light; }
  void toggleTheme() { setState(() => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light); widget.prefs.setBool('dark_mode', mode == ThemeMode.dark); }
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Business360', themeMode: mode,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C57F5)),
    darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF8B7CFF), brightness: Brightness.dark),
    home: HomeScreen(index: index, onIndexChanged: (v) => setState(() => index = v), onTheme: toggleTheme, dark: mode == ThemeMode.dark),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.index, required this.onIndexChanged, required this.onTheme, required this.dark});
  final int index; final ValueChanged<int> onIndexChanged; final VoidCallback onTheme; final bool dark;
  static const pages = ['Dashboard', 'Sales / POS', 'Products & Stock', 'Customers', 'Reports'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Business360'), actions: [IconButton(onPressed: onTheme, icon: Icon(dark ? Icons.light_mode : Icons.dark_mode))]),
    drawer: Drawer(child: SafeArea(child: ListView(padding: const EdgeInsets.all(12), children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Business360', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      for (var i = 0; i < pages.length; i++) ListTile(leading: Icon([Icons.dashboard, Icons.point_of_sale, Icons.inventory_2, Icons.people, Icons.bar_chart][i]), title: Text(pages[i]), selected: index == i, onTap: () { Navigator.pop(context); onIndexChanged(i); }),
    ]))),
    body: SafeArea(child: index == 0 ? const DashboardPage() : ModulePage(title: pages[index])),
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: onIndexChanged, destinations: const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
      NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
      NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
      NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
      NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
    ]),
  );
}

class ModulePage extends StatelessWidget {
  const ModulePage({super.key, required this.title}); final String title;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [Text(title, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 16), Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('$title module is ready for feature-by-feature migration.')))]);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cards = [('Sales', '৳ 0.00', Icons.point_of_sale), ('Products', '0', Icons.inventory_2), ('Customers', '0', Icons.people), ('Due', '৳ 0.00', Icons.account_balance_wallet)];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Business360', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Smart Business Management')]))),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: cards.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35), itemBuilder: (_, i) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(cards[i].$3, size: 30), const SizedBox(height: 10), Text(cards[i].$1), const SizedBox(height: 4), Text(cards[i].$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))])))),
    ]);
  }
}
