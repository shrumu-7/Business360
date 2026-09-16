import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllThemeScreen extends StatelessWidget {
  const AllThemeScreen({super.key, required this.prefs, required this.onApplied});
  final SharedPreferences prefs;
  final VoidCallback onApplied;

  static const themes = <String, Map<String, dynamic>>{
    'purple': {'name':'Purple','seed':Color(0xFF6C57F5),'bg':Color(0xFFF4F0FF),'appBg':'blueWhite','dash':'plain'},
    'blue': {'name':'Ocean Blue','seed':Color(0xFF087EA4),'bg':Color(0xFFEAF7FB),'appBg':'blueWhite','dash':'blue'},
    'green': {'name':'Emerald','seed':Color(0xFF15803D),'bg':Color(0xFFECFDF3),'appBg':'cream','dash':'plain'},
    'rose': {'name':'Rose','seed':Color(0xFFE11D48),'bg':Color(0xFFFFF1F2),'appBg':'blueWhite','dash':'plain'},
    'orange': {'name':'Orange','seed':Color(0xFFEA580C),'bg':Color(0xFFFFF7ED),'appBg':'cream','dash':'plain'},
    'dark': {'name':'Midnight Dark','seed':Color(0xFF686FF0),'bg':Color(0xFF0E1420),'appBg':'midnight','dash':'midnight'},
    'sky': {'name':'Sky','seed':Color(0xFF0284C7),'bg':Color(0xFFF0F9FF),'appBg':'blueWhite','dash':'blue'},
    'cream': {'name':'Cream','seed':Color(0xFFD97706),'bg':Color(0xFFFFF8EA),'appBg':'cream','dash':'plain'},
    'mint': {'name':'Mint','seed':Color(0xFF059669),'bg':Color(0xFFECFDF5),'appBg':'blueWhite','dash':'plain'},
    'premium': {'name':'Premium','seed':Color(0xFFB08D57),'bg':Color(0xFFFAF7F0),'appBg':'cream','dash':'plain'},
    'light': {'name':'Light','seed':Color(0xFF64748B),'bg':Color(0xFFF8FAFC),'appBg':'blueWhite','dash':'plain'},
    'ocean': {'name':'Deep Ocean','seed':Color(0xFF0369A1),'bg':Color(0xFFEFF6FF),'appBg':'blueWhite','dash':'blue'},
    'sunset': {'name':'Sunset','seed':Color(0xFFF97316),'bg':Color(0xFFFFF7ED),'appBg':'cream','dash':'plain'},
    'aurora': {'name':'Aurora','seed':Color(0xFF7C3AED),'bg':Color(0xFFF5F3FF),'appBg':'blueWhite','dash':'plain'},
    'forest': {'name':'Forest','seed':Color(0xFF166534),'bg':Color(0xFFF0FDF4),'appBg':'cream','dash':'plain'},
    'gold': {'name':'Gold','seed':Color(0xFFCA8A04),'bg':Color(0xFFFEFCE8),'appBg':'cream','dash':'plain'},
  };

  Future<void> apply(BuildContext context, String key) async {
    final data = themes[key]!;
    await prefs.setString('theme', key);
    await prefs.setString('appBg', data['appBg'] as String);
    await prefs.setString('dashboardBg', data['dash'] as String);
    await prefs.setString('dashboardCardBg', key == 'dark' ? 'glass' : 'gradient');
    await prefs.setString('dashboardBorder', key == 'dark' ? 'glow' : 'normal');
    onApplied();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selected = prefs.getString('theme') ?? 'purple';
    return Scaffold(
      appBar: AppBar(title: const Text('All Theme')),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .82),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final entry = themes.entries.elementAt(index); final data = entry.value; final active = selected == entry.key; final seed = data['seed'] as Color; final bg = data['bg'] as Color;
            return InkWell(
              borderRadius: BorderRadius.circular(20), onTap: () => apply(context, entry.key),
              child: Card(
                clipBehavior: Clip.antiAlias, elevation: active ? 8 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: seed, width: active ? 3 : 1)),
                child: Column(children: [
                  Expanded(child: Container(color: bg, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(height: 28, decoration: BoxDecoration(color: seed, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 12),
                    Expanded(child: Row(children: [Expanded(child: Container(decoration: BoxDecoration(color: seed, borderRadius: BorderRadius.circular(12)))), const SizedBox(width: 8), Expanded(child: Container(decoration: BoxDecoration(color: seed.withValues(alpha:.55), borderRadius: BorderRadius.circular(12))))])),
                  ]))),
                  Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: Text(data['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold))), if (active) const Icon(Icons.check_circle)])),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
