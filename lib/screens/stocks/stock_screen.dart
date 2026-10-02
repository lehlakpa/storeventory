import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import '../../widgets/run_mutation.dart';
import '../../widgets/reauthenticate_dialog.dart';
import '../../widgets/update_stock_dialog.dart';
import '../../models/product_ui_model.dart';
import '../../widgets/product_tile.dart';
import '../categories/category_screen.dart';
import '../sales/record_sale_screen.dart';
import 'product_details_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, this.category});
  final String? category;
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateStock(ProductUiModel product) =>
      showUpdateStockDialog(context, product);

  Future<void> _deleteStock(ProductUiModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Stock'),
        content: Text('Remove ${product.name} and its stock from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Stock'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (!await confirmSensitiveAction(context) || !mounted) return;
    final deleted = await runMutation(context, () async {
      await context.read<InventoryCubit>().remove(product.id);
      return true;
    });
    if (deleted != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} removed from inventory.')),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.category ?? 'Stocks'),
        bottom: widget.category == null
            ? TabBar(
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                dividerColor: Theme.of(context).colorScheme.outlineVariant,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Products'),
                  Tab(text: 'Category'),
                ],
              )
            : null,
      ),
      body: widget.category == null
          ? TabBarView(
              children: [_products(), const CategoryScreen(embedded: true)],
            )
          : _products(),
    ),
  );

  Widget _products() => InventoryBuilder(
    builder: (context, _) {
      final products = context
          .read<InventoryCubit>()
          .products
          .where(
            (p) =>
                (widget.category == null || p.category == widget.category) &&
                p.name.toLowerCase().contains(_query.trim().toLowerCase()),
          )
          .toList();
      return Column(
        children: [
          Padding(
            padding: AppSizes.screenHeaderPadding,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'Search products...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.spacing12,
                ),
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: AppSizes.screenPadding,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordSaleScreen()),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Record Sale'),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Total Products: ${products.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing12),
                if (products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: Center(child: Text('No products found')),
                  ),
                ...products.map(
                  (p) => ProductTile(
                    image: p.imageUrl,
                    name: p.name,
                    quantity: '${p.quantity} ${p.unit}',
                    status: p.status,
                    onUpdateStock: () => _updateStock(p),
                    onDeleteStock: () => _deleteStock(p),
                    onRecordSale: p.quantity > 0
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordSaleScreen(initialProductId: p.id),
                            ),
                          )
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(productId: p.id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
