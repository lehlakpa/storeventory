import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../blocs/inventory_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/inventory_builder.dart';
import 'record_sale_screen.dart';
import 'sale_details_screen.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sales')),
    body: InventoryBuilder(
      builder: (context, _) {
        final sales = context.read<InventoryCubit>().sales.reversed.toList();
        final total = sales.fold<double>(
          0,
          (sum, sale) => sum + sale.totalAmount,
        );
        return ListView(
          padding: const EdgeInsets.all(18),
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
                const SizedBox(width: 12),
                Expanded(child: _summary('Receipts', '${sales.length}', false)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordSaleScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Receipt'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sales receipts',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (sales.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.textHint,
                      size: 38,
                    ),
                    SizedBox(height: 12),
                    Text('No sales yet'),
                    SizedBox(height: 6),
                    Text(
                      'Record a sale to create your first receipt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ...sales.map(
              (sale) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
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
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: primary ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: primary ? Colors.white : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primary ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
