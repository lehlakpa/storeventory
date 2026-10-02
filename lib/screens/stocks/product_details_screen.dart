import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import '../../widgets/run_mutation.dart';
import '../../widgets/reauthenticate_dialog.dart';
import '../../widgets/product_image.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/update_stock_dialog.dart';
import 'add_product_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) => InventoryBuilder(
    builder: (context, _) {
      final p = context.read<InventoryCubit>().product(productId);
      if (p == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Product no longer available')),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: ListView(
          padding: AppSizes.screenPadding,
          children: [
            Container(
              height: 230,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ProductImage(url: p.imageUrl),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(status: p.status),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Info(title: 'Category', value: p.category),
                ),
                Expanded(
                  child: _Info(
                    title: 'Quantity',
                    value: '${p.quantity} ${p.unit}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: _Info(
                    title: 'Purchase Price',
                    value: 'Ns ${p.purchasePrice.toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: _Info(
                    title: 'Selling Price',
                    value: 'Ns ${p.price.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: AppSizes.cardPadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _Info(
                title: 'Total Value',
                value: 'Ns ${(p.price * p.quantity).toStringAsFixed(0)}',
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              width: double.infinity,
              padding: AppSizes.cardPadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _Info(
                title: 'Note',
                value: p.note.isEmpty ? 'No note added' : p.note,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(product: p),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Edit'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () async {
                      final remove = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete ${p.name}?'),
                          content: const Text(
                            'This removes the product from your inventory.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (remove == true && context.mounted) {
                        if (!await confirmSensitiveAction(context) ||
                            !context.mounted) {
                          return;
                        }
                        final deleted = await runMutation(context, () async {
                          await context.read<InventoryCubit>().remove(p.id);
                          return true;
                        });
                        if (deleted == true && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Delete'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  flex: 5,
                  child: ElevatedButton(
                    onPressed: () => showUpdateStockDialog(context, p),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Update Stock'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.title, required this.value});
  final String title, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: AppSizes.sm),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ],
  );
}
