import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> open(String value) async {
    final uri = Uri.parse(value);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Developer')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 46)),
          const SizedBox(height: 14),
          const Center(child: Text('Md Sahadul Hoque Rumu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          const Center(child: Text('Founder & Developer · Business360')),
          const SizedBox(height: 28),
          Card(child: ListTile(leading: const Icon(Icons.chat), title: const Text('WhatsApp'), subtitle: const Text('01795934394'), trailing: const Icon(Icons.open_in_new), onTap: () => open('https://wa.me/8801795934394'))),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Icon(Icons.email), title: const Text('Gmail'), subtitle: const Text('shrumu7@gmail.com'), trailing: const Icon(Icons.open_in_new), onTap: () => open('mailto:shrumu7@gmail.com'))),
          const SizedBox(height: 22),
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Business360 is a business management application for products, sales, customers, stock, purchases, expenses, reports and business records.'))),
        ],
      ),
    );
  }
}
