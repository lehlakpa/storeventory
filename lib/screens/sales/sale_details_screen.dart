import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/sale_ui_model.dart';
import '../../widgets/product_image.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/inventory_cubit.dart';
import '../../widgets/run_mutation.dart';
import '../../widgets/reauthenticate_dialog.dart';
import 'record_sale_screen.dart';

class SaleDetailsScreen extends StatefulWidget {
  const SaleDetailsScreen({super.key, required this.sale});
  final SaleUiModel sale;

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  late SaleUiModel sale = widget.sale;
  bool _busy = false;

  Future<void> _edit() async {
    final updated = await Navigator.push<SaleUiModel>(
      context,
      MaterialPageRoute(builder: (_) => RecordSaleScreen(sale: sale)),
    );
    if (mounted && updated != null) setState(() => sale = updated);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: const Text(
          'This will permanently delete the receipt and restore its quantity to stock if the product still exists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!await confirmSensitiveAction(context) || !mounted) return;
    setState(() => _busy = true);
    final success = await runMutation(context, () async {
      await context.read<InventoryCubit>().deleteSale(sale.id);
      return true;
    });
    if (!mounted) return;
    if (success == true) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Receipt #${sale.id}')),
    body: ListView(
      padding: AppSizes.screenPadding,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
                size: 40,
              ),
              const SizedBox(height: AppSizes.spacing12),
              const Text(
                'STOREVENTORY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'SALES RECEIPT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              _line('Receipt number', '#${sale.id}'),
              const SizedBox(height: AppSizes.spacing12),
              _line('Date', sale.formattedDate),
              Divider(
                height: 32,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Text(
                'BILL TO',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.spacing12),
              Text(
                sale.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                sale.address,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                sale.phone,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Divider(
                height: 32,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ProductImage(
                      url: sale.imageUrl,
                      width: 44,
                      height: 52,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          '${sale.quantity} ${sale.unit} x Ns ${sale.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              _line('Subtotal', 'Ns ${sale.totalAmount.toStringAsFixed(2)}'),
              Divider(
                height: 28,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Container(
                padding: AppSizes.cardPadding,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: _line(
                  'TOTAL',
                  'Ns ${sale.totalAmount.toStringAsFixed(2)}',
                  bold: true,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Thank you for your purchase!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            _receiptAction(
              label: 'Edit',
              icon: Icons.edit_outlined,
              flex: 3,
              onPressed: _edit,
            ),
            const SizedBox(width: AppSizes.sm),
            _receiptAction(
              label: 'Delete',
              icon: Icons.delete_outline,
              flex: 4,
              color: Theme.of(context).colorScheme.error,
              onPressed: _delete,
            ),
            const SizedBox(width: AppSizes.sm),
            _receiptAction(
              label: 'Copy Receipt',
              icon: Icons.copy_outlined,
              flex: 6,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: sale.receiptText));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt copied.')),
                );
              },
            ),
          ],
        ),
      ],
    ),
  );

  Widget _receiptAction({
    required String label,
    required IconData icon,
    required int flex,
    required VoidCallback onPressed,
    Color? color,
  }) => Expanded(
    flex: flex,
    child: OutlinedButton(
      onPressed: _busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        minimumSize: const Size(0, 48),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: AppSizes.xs),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ),
  );

  Widget _line(String label, String value, {bool bold = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: bold
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: AppSizes.spacing12),
      Flexible(
        flex: 2,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: bold ? 18 : 12,
          ),
        ),
      ),
    ],
  );
}
