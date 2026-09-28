import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import '../../widgets/update_stock_dialog.dart';
import '../../models/product_ui_model.dart';
import '../../widgets/product_image.dart';
import '../sales/record_sale_screen.dart';
import '../sales/sales_screen.dart';
import '../settings/profile_screen.dart';
import '../stocks/add_product_screen.dart';
import '../stocks/product_details_screen.dart';
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

  Future<void> _restock(BuildContext context, ProductUiModel p) =>
      showUpdateStockDialog(context, p, increment: true);

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
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
        icon: CircleAvatar(
          radius: 17,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
        const SizedBox(width: AppSizes.sm),
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
            padding: AppSizes.screenPadding,
            children: [
              Container(
                padding: AppSizes.cardPadding,
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
                    const SizedBox(height: AppSizes.lg),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _SummaryItem(
                            title: 'Total Value',
                            value: 'Ns ${store.totalValue.toStringAsFixed(0)}',
                          ),
                        ),
                        const SizedBox(
                          height: 44,
                          child: VerticalDivider(
                            width: 17,
                            thickness: 1,
                            color: Colors.white38,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _SummaryItem(
                            title: 'Total Stock',
                            value: '${store.totalStock}',
                          ),
                        ),
                        const SizedBox(
                          height: 44,
                          child: VerticalDivider(
                            width: 17,
                            thickness: 1,
                            color: Colors.white38,
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
              const SizedBox(height: AppSizes.lg),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSizes.spacing12),
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
                  const SizedBox(width: AppSizes.sm),
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
                  const SizedBox(width: AppSizes.sm),
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
              const SizedBox(height: AppSizes.md),
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
                  context,
                  store.products.isEmpty
                      ? 'No products yet. Add your first product.'
                      : 'All products are in stock.',
                ),
              ...out.map((p) => _stockRow(context, p)),
              if (low.isNotEmpty) ...[
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Running low',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.spacing12),
                ...low.map((p) => _stockRow(context, p)),
              ],
            ],
          );
        },
      ),
    ),
  );

  Widget _empty(BuildContext context, String text) => Container(
    padding: AppSizes.cardPadding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );

  Widget _stockRow(BuildContext context, ProductUiModel p) => Container(
    margin: const EdgeInsets.only(bottom: AppSizes.sm),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: p.id),
          ),
        ),
        child: Padding(
          padding: AppSizes.tilePadding,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: ProductImage(
                    url: p.imageUrl,
                    width: 48,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),
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
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'QTY: ${p.quantity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: p.quantity == 0
                            ? AppColors.danger
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing12,
                  ),
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
        ),
      ),
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
      const SizedBox(height: AppSizes.sm),
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
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: AppSizes.spacing12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    onPressed: onTap,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppSizes.xs),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}
