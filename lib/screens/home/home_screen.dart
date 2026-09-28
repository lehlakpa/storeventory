import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import '../../widgets/run_mutation.dart';
import '../../models/product_ui_model.dart';
import '../../widgets/product_image.dart';
import '../sales/record_sale_screen.dart';
import '../sales/sales_screen.dart';
import '../settings/settings_screen.dart';
import '../stocks/add_product_screen.dart';
import '../stocks/stock_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onViewInventory,
    this.onOpenProfile,
    this.onViewSales,
  });
  final VoidCallback? onViewInventory;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onViewSales;

  void _inventory(BuildContext context) {
    if (onViewInventory != null) {
      onViewInventory!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StockScreen()),
      );
    }
  }

  Future<void> _restock(BuildContext context, ProductUiModel p) async {
    int amount = 0;
    String? error;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Restock ${p.name}'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            onChanged: (value) => amount = int.tryParse(value) ?? 0,
            decoration: InputDecoration(
              labelText: 'Quantity to add',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (amount <= 0) {
                  update(() => error = 'Enter a positive whole number');
                  return;
                }
                Navigator.pop(context, amount);
              },
              child: const Text('Restock'),
            ),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      await runMutation(context, () async {
        await context.read<InventoryCubit>().changeStock(
          p.id,
          result,
          increment: true,
        );
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Home'),
      leading: IconButton(
        tooltip: 'Profile',
        onPressed:
            onOpenProfile ??
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
        icon: const CircleAvatar(
          radius: 17,
          backgroundColor: AppColors.lightBlue,
          child: Icon(Icons.person_outline, color: AppColors.primary, size: 22),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Sales',
          onPressed:
              onViewSales ??
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesScreen()),
              ),
          icon: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: InventoryBuilder(
        builder: (context, _) {
          final store = context.read<InventoryCubit>();
          final out = store.products.where((p) => p.quantity == 0).toList();
          final low = store.products
              .where((p) => p.quantity > 0 && p.quantity <= p.minimumStock)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF079AFF), AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _SummaryItem(
                            title: 'Total Value',
                            value: 'Ns ${store.totalValue.toStringAsFixed(0)}',
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _SummaryItem(
                            title: 'Total Stock',
                            value: '${store.totalStock}',
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _SummaryItem(
                            title: 'Low Stock',
                            value: '${store.lowStockCount}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _QuickAction(
                      icon: Icons.add,
                      label: 'Add',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    flex: 4,
                    child: _QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Record',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecordSaleScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    flex: 5,
                    child: _QuickAction(
                      icon: Icons.inventory_2_outlined,
                      label: 'View Inventory',
                      onTap: () => _inventory(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Items out of stock',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _inventory(context),
                    child: const Text(
                      'View All',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (out.isEmpty)
                _empty(
                  store.products.isEmpty
                      ? 'No products yet. Add your first product.'
                      : 'All products are in stock.',
                ),
              ...out.map((p) => _stockRow(context, p)),
              if (low.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Running low',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...low.map((p) => _stockRow(context, p)),
              ],
            ],
          );
        },
      ),
    ),
  );

  Widget _empty(String text) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
  );

  Widget _stockRow(BuildContext context, ProductUiModel p) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: ColoredBox(
            color: AppColors.surface,
            child: ProductImage(
              url: p.imageUrl,
              width: 48,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'QTY: ${p.quantity}',
                style: TextStyle(
                  fontSize: 11,
                  color: p.quantity == 0 ? AppColors.danger : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: const Size(0, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: () => _restock(context, p),
          child: const Text('Restock', style: TextStyle(fontSize: 11)),
        ),
      ],
    ),
  );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.title, required this.value});
  final String title, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
      const SizedBox(height: 7),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    onPressed: onTap,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}
