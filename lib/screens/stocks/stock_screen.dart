import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import '../../widgets/run_mutation.dart';
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
  bool _searching = false;
  String _query = '';

  Future<void> _updateStock(ProductUiModel product) async {
    final formKey = GlobalKey<FormState>();
    int quantity = product.quantity;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        void save() {
          if (!formKey.currentState!.validate()) return;
          formKey.currentState!.save();
          Navigator.pop(dialogContext, quantity);
        }

        return AlertDialog(
          title: const Text('Update Stock'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('Current stock: ${product.quantity} ${product.unit}'),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: '${product.quantity}',
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'New stock quantity',
                    helperText: 'Replaces the current quantity.',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    return parsed == null || parsed < 0
                        ? 'Enter a whole number of 0 or more'
                        : null;
                  },
                  onSaved: (value) => quantity = int.parse(value!.trim()),
                  onFieldSubmitted: (_) => save(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(onPressed: save, child: const Text('Update Stock')),
          ],
        );
      },
    );
    if (!mounted || result == null) return;
    final current = context.read<InventoryCubit>().product(product.id);
    if (current == null) return;
    final saved = await runMutation(context, () async {
      await context.read<InventoryCubit>().changeStock(current.id, result);
      return true;
    });
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${current.name} stock updated to $result ${current.unit}.',
        ),
      ),
    );
  }

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
        actions: [
          IconButton(
            tooltip: 'Search products',
            onPressed: () => setState(() {
              _searching = !_searching;
              _query = '';
            }),
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
        ],
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
                p.name.toLowerCase().contains(_query.toLowerCase()),
          )
          .toList();
      return Column(
        children: [
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordSaleScreen()),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Record Sale'),
                ),
                const SizedBox(height: 18),
                Text(
                  'Total Products: ${products.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
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
