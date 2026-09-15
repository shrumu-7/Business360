import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/business_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.prefs, required this.store, required this.onChanged});
  final SharedPreferences prefs;
  final BusinessStore store;
  final VoidCallback onChanged;
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController shop, address, phone, currency, prefix, lowStock, pin;
  String theme = 'purple', appBg = 'blueWhite', dashboardBg = 'midnight', cardBg = 'gradient', border = 'glow', buttonTheme = 'neon', security = 'none';
  bool logoRemoved = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefs;
    shop = TextEditingController(text: p.getString('shop') ?? 'আমার দোকান');
    address = TextEditingController(text: p.getString('address') ?? '');
    phone = TextEditingController(text: p.getString('phone') ?? '');
    currency = TextEditingController(text: p.getString('currency') ?? '৳');
    prefix = TextEditingController(text: p.getString('invoicePrefix') ?? 'INV');
    lowStock = TextEditingController(text: '${p.getInt('lowStock') ?? 5}');
    pin = TextEditingController();
    theme = p.getString('theme') ?? 'purple';
    appBg = p.getString('appBg') ?? 'blueWhite';
    dashboardBg = p.getString('dashboardBg') ?? 'midnight';
    cardBg = p.getString('dashboardCardBg') ?? 'gradient';
    border = p.getString('dashboardBorder') ?? 'glow';
    buttonTheme = p.getString('buttonTheme') ?? 'neon';
    security = p.getString('securityMode') ?? 'none';
    logoRemoved = p.getBool('logoRemoved') ?? false;
  }

  @override
  void dispose() {
    for (final c in [shop, address, phone, currency, prefix, lowStock, pin]) c.dispose();
    super.dispose();
  }

  InputDecoration deco(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder());

  Future<void> save() async {
    final p = widget.prefs;
    await p.setString('shop', shop.text.trim().isEmpty ? 'আমার দোকান' : shop.text.trim());
    await p.setString('address', address.text.trim());
    await p.setString('phone', phone.text.trim());
    await p.setString('currency', currency.text.trim().isEmpty ? '৳' : currency.text.trim());
    await p.setString('invoicePrefix', prefix.text.trim().isEmpty ? 'INV' : prefix.text.trim());
    await p.setInt('lowStock', int.tryParse(lowStock.text) ?? 5);
    await p.setString('theme', theme);
    await p.setString('appBg', appBg);
    await p.setString('dashboardBg', dashboardBg);
    await p.setString('dashboardCardBg', cardBg);
    await p.setString('dashboardBorder', border);
    await p.setString('buttonTheme', buttonTheme);
    await p.setBool('logoRemoved', logoRemoved);
    await p.setString('securityMode', security);
    if (security == 'pin' && pin.text.trim().isNotEmpty) await p.setString('pinCode', pin.text.trim());
    if (security == 'none') await p.remove('pinCode');
    widget.onChanged();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
  }

  Future<void> backup() async {
    await widget.store.saveSafetyBackup();
    final text = await widget.store.exportJson();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Safety backup created and JSON copied')));
  }

  Future<void> restore() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup JSON not found in clipboard')));
      return;
    }
    try {
      await widget.store.restoreJson(text);
      widget.onChanged();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored successfully')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Business360 backup')));
    }
  }

  Widget select(String label, String value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged, IconData icon) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(initialValue: value, decoration: deco(label, icon), items: items, onChanged: onChanged));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Business & Branding', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: shop, decoration: deco('Shop name', Icons.store)),
        const SizedBox(height: 10),
        TextField(controller: address, decoration: deco('Address', Icons.location_on)),
        const SizedBox(height: 10),
        TextField(controller: phone, decoration: deco('Phone', Icons.phone)),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: currency, decoration: deco('Currency', Icons.currency_exchange))), const SizedBox(width: 10), Expanded(child: TextField(controller: prefix, decoration: deco('Invoice prefix', Icons.receipt_long)))]),
        const SizedBox(height: 10),
        TextField(controller: lowStock, keyboardType: TextInputType.number, decoration: deco('Low stock alert', Icons.warning_amber)),
        const SizedBox(height: 22),
        const Text('Theme & Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        select('Theme', theme, const [DropdownMenuItem(value: 'purple', child: Text('Purple')), DropdownMenuItem(value: 'blue', child: Text('Ocean Blue')), DropdownMenuItem(value: 'green', child: Text('Emerald')), DropdownMenuItem(value: 'dark', child: Text('Midnight Dark'))], (v) { if (v != null) setState(() => theme = v); }, Icons.palette),
        select('Whole app background', appBg, const [DropdownMenuItem(value: 'blueWhite', child: Text('Blue / White')), DropdownMenuItem(value: 'midnight', child: Text('Midnight')), DropdownMenuItem(value: 'slate', child: Text('Slate')), DropdownMenuItem(value: 'cream', child: Text('Cream'))], (v) { if (v != null) setState(() => appBg = v); }, Icons.wallpaper),
        select('Dashboard background', dashboardBg, const [DropdownMenuItem(value: 'midnight', child: Text('Midnight')), DropdownMenuItem(value: 'blue', child: Text('Ocean')), DropdownMenuItem(value: 'plain', child: Text('Plain'))], (v) { if (v != null) setState(() => dashboardBg = v); }, Icons.dashboard_customize),
        select('Dashboard card style', cardBg, const [DropdownMenuItem(value: 'gradient', child: Text('Gradient style')), DropdownMenuItem(value: 'solid', child: Text('Solid')), DropdownMenuItem(value: 'glass', child: Text('Glass'))], (v) { if (v != null) setState(() => cardBg = v); }, Icons.dashboard),
        select('Dashboard border', border, const [DropdownMenuItem(value: 'glow', child: Text('Glow')), DropdownMenuItem(value: 'normal', child: Text('Normal')), DropdownMenuItem(value: 'none', child: Text('None'))], (v) { if (v != null) setState(() => border = v); }, Icons.border_style),
        select('Button style', buttonTheme, const [DropdownMenuItem(value: 'neon', child: Text('Neon')), DropdownMenuItem(value: 'classic', child: Text('Classic')), DropdownMenuItem(value: 'minimal', child: Text('Minimal'))], (v) { if (v != null) setState(() => buttonTheme = v); }, Icons.smart_button),
        SwitchListTile(title: const Text('Show logo placeholder'), subtitle: const Text('Keeps the branding area visible until the original logo asset is restored'), value: !logoRemoved, onChanged: (v) => setState(() => logoRemoved = !v)),
        const SizedBox(height: 12),
        const Text('Security', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        select('Security mode', security, const [DropdownMenuItem(value: 'none', child: Text('Off')), DropdownMenuItem(value: 'pin', child: Text('PIN'))], (v) { if (v != null) setState(() => security = v); }, Icons.lock),
        if (security == 'pin') TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number, decoration: deco('App PIN', Icons.password)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('Save all settings')),
        const SizedBox(height: 24),
        const Text('Backup & Restore', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Business data is stored locally. Create a safety backup before changing or reinstalling the app.'),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: backup, icon: const Icon(Icons.backup), label: const Text('Create safety backup + copy JSON')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: restore, icon: const Icon(Icons.restore), label: const Text('Restore JSON from clipboard')),
      ],
    );
  }
}
