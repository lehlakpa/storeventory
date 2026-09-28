import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'product_image.dart';
import 'status_badge.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.image,
    required this.name,
    required this.quantity,
    required this.status,
    this.onTap,
    this.onUpdateStock,
    this.onDeleteStock,
    this.onRecordSale,
  });
  final String image;
  final String name;
  final String quantity;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onUpdateStock;
  final VoidCallback? onDeleteStock;
  final VoidCallback? onRecordSale;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: AppColors.surface,
                  child: ProductImage(
                    url: image,
                    width: 54,
                    height: 58,
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
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Qty: $quantity',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (onUpdateStock != null || onDeleteStock != null) ...[
                      const SizedBox(height: 6),
                      StatusBadge(status: status),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (onUpdateStock == null && onDeleteStock == null)
                StatusBadge(status: status)
              else
                PopupMenuButton<String>(
                  tooltip: 'Stock options for $name',
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (action) {
                    if (action == 'update') onUpdateStock?.call();
                    if (action == 'delete') onDeleteStock?.call();
                    if (action == 'sale') onRecordSale?.call();
                  },
                  itemBuilder: (_) => [
                    if (onRecordSale != null)
                      const PopupMenuItem(
                        value: 'sale',
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 19,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Text('Record Sale'),
                          ],
                        ),
                      ),
                    if (onUpdateStock != null)
                      const PopupMenuItem(
                        value: 'update',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 19,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Text('Update Stock'),
                          ],
                        ),
                      ),
                    if (onDeleteStock != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 19,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete Stock',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
