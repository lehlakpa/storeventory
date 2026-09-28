import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import 'record_sale_screen.dart';
import 'sale_details_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sales')),
    body: InventoryBuilder(
      builder: (context, _) {
        final sales = context.read<InventoryCubit>().sales.reversed.toList();
        final filtered = sales
            .where((sale) => sale.matchesSearch(_query))
            .toList();
        final total = sales.fold<double>(
          0,
          (sum, sale) => sum + sale.totalAmount,
        );
        return ListView(
          padding: AppSizes.screenPadding,
          children: [
            Row(
              children: [
                Expanded(
                  child: _summary(
                    'Total Sales',
                    'Ns ${total.toStringAsFixed(2)}',
                    true,
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(child: _summary('Receipts', '${sales.length}', false)),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordSaleScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Receipt'),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'Sales receipts',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: AppSizes.spacing12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or number',
                hintText: 'Customer name, phone or receipt number',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSizes.spacing12),
            if (filtered.isEmpty && sales.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSizes.lg),
                child: Text('No matching receipts found.'),
              ),
            if (sales.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 38,
                    ),
                    SizedBox(height: AppSizes.spacing12),
                    Text('No sales yet'),
                    SizedBox(height: AppSizes.sm),
                    Text(
                      'Record a sale to create your first receipt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ...filtered.map(
              (sale) => Container(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.sm,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    '#${sale.id} - ${sale.customerName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSizes.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Ns ${sale.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaleDetailsScreen(sale: sale),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _summary(String label, String value, bool primary) => Container(
    padding: AppSizes.cardPadding,
    decoration: BoxDecoration(
      color: primary
          ? AppColors.primary
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: primary
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primary
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}
