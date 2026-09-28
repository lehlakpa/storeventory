import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About Storeventory')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Storeventory',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Version 1.0.0', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Text(
          'Manage your store in one place. Keep track of products, monitor stock levels, and record sales with customer receipts.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('Inventory'),
                subtitle: Text('Organize products and categories.'),
              ),
              ListTile(
                leading: Icon(Icons.warehouse_outlined),
                title: Text('Stock tracking'),
                subtitle: Text('Restock products and track low stock.'),
              ),
              ListTile(
                leading: Icon(Icons.receipt_long_outlined),
                title: Text('Sales receipts'),
                subtitle: Text('Create, search, edit and delete receipts.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Storeventory',
            applicationVersion: '1.0.0',
          ),
          child: const Text('Open-source licenses'),
        ),
      ],
    ),
  );
}
