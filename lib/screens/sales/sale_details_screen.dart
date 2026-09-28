import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/sale_ui_model.dart';
import '../../widgets/product_image.dart';

class SaleDetailsScreen extends StatelessWidget {
  const SaleDetailsScreen({super.key, required this.sale});
  final SaleUiModel sale;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Receipt #${sale.id}')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
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
              const SizedBox(height: 10),
              const Text(
                'STOREVENTORY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'SALES RECEIPT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _line('Receipt number', '#${sale.id}'),
              const SizedBox(height: 10),
              _line('Date', sale.formattedDate),
              const Divider(height: 32, color: AppColors.border),
              const Text(
                'BILL TO',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                sale.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sale.address,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                sale.phone,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Divider(height: 32, color: AppColors.border),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${sale.quantity} ${sale.unit} x Ns ${sale.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _line('Subtotal', 'Ns ${sale.totalAmount.toStringAsFixed(2)}'),
              const Divider(height: 28, color: AppColors.border),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: _line(
                  'TOTAL',
                  'Ns ${sale.totalAmount.toStringAsFixed(2)}',
                  bold: true,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank you for your purchase!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: sale.receiptText));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Receipt copied.')));
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy Receipt'),
        ),
      ],
    ),
  );

  Widget _line(String label, String value, {bool bold = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: 12),
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
