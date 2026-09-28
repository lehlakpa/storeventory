import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => url.trim().isEmpty
      ? SizedBox(
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.inventory_2_outlined)),
        )
      : Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: Icon(Icons.image_outlined)),
          errorBuilder: (context, error, stack) => SizedBox(
            width: width,
            height: height,
            child: const Center(child: Icon(Icons.inventory_2_outlined)),
          ),
        );
}
