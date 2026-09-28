import 'package:flutter/material.dart';

import 'product_image.dart';

class ProductStockTile extends StatelessWidget {
  const ProductStockTile({
    super.key,
    required this.image,
    required this.name,
    required this.quantity,
    required this.onRestock,
  });
  final String image;
  final String name;
  final int quantity;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: ProductImage(url: image, width: 48, height: 48),
    title: Text(name),
    subtitle: Text('Qty: $quantity'),
    trailing: TextButton(onPressed: onRestock, child: const Text('Restock')),
  );
}
