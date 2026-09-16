import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllThemeScreen extends StatelessWidget {
  const AllThemeScreen({super.key, required this.prefs, required this.onApplied});

  final SharedPreferences prefs;
  final VoidCallback onApplied;

  static const themes = <String, Map<String, dynamic>>{
    'purple': {'name': 'Purple', 'seed': Color(0xFF6C57F5), 'bg': Color(0xFFF4F0FF)},
    'blue': {'name': 'Ocean Blue', 'seed': Color(0xFF087EA4), 'bg': Color(0xFFEAF7FB)},
    'green': {'name': 'Emerald', 'seed': Color(0xFF15803D), 'bg': Color(0xFFECFDF3)},
    'dark': {'name': 'Midnight Dark', 'seed': Color(0xFF686FF0), 'bg': Color(0xFF0E1420)},
  };

  Future<void> apply(BuildContext context, String key) async {
    await prefs.setString('theme', key);
    final bg = key == 'dark' ? 'midnight' : key == 'blue' ? 'blueWhite' : key == 'green' ? 'cream' : 'blueWhite';
    await prefs.setString('appBg', bg);
    await prefs.setString('dashboardBg', key == 'dark' ? 'midnight' : key == 'blue' ? 'blue' : 'plain');
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: .82,
          ),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final entry = themes.entries.elementAt(index);
            final data = entry.value;
            final active = selected == entry.key;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => apply(context, entry.key),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: active ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: data['seed'] as Color, width: active ? 3 : 1),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: data['bg'] as Color,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(height: 28, decoration: BoxDecoration(color: data['seed'] as Color, borderRadius: BorderRadius.circular(10))),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: Container(decoration: BoxDecoration(color: data['seed'] as Color, borderRadius: BorderRadius.circular(12)))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Container(decoration: BoxDecoration(color: (data['seed'] as Color).withValues(alpha: .55), borderRadius: BorderRadius.circular(12)))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [Expanded(child: Text(data['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold))), if (active) const Icon(Icons.check_circle)]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
