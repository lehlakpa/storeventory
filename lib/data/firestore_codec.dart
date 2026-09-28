import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_ui_model.dart';
import '../models/sale_ui_model.dart';

ProductUiModel productFromMap(String id, Map<String, dynamic> d) =>
    ProductUiModel(
      id: id,
      name: d['name'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      imagePublicId: d['imagePublicId'] as String? ?? '',
      imageFileName: d['imageFileName'] as String? ?? '',
      imageSizeBytes: (d['imageSizeBytes'] as num? ?? 0).toInt(),
      price: (d['price'] as num? ?? 0).toDouble(),
      purchasePrice: (d['purchasePrice'] as num? ?? 0).toDouble(),
      quantity: (d['quantity'] as num? ?? 0).toInt(),
      minimumStock: (d['minimumStock'] as num? ?? 0).toInt(),
      category: d['category'] as String? ?? '',
      unit: d['unit'] as String? ?? '',
    );

Map<String, dynamic> productToMap(ProductUiModel p) => {
  'name': p.name,
  'imageUrl': p.imageUrl,
  'imagePublicId': p.imagePublicId,
  'imageFileName': p.imageFileName,
  'imageSizeBytes': p.imageSizeBytes,
  'price': p.price,
  'purchasePrice': p.purchasePrice,
  'quantity': p.quantity,
  'minimumStock': p.minimumStock,
  'category': p.category,
  'unit': p.unit,
};

SaleUiModel saleFromMap(String id, Map<String, dynamic> d) => SaleUiModel(
  id: id,
  customerName: d['customerName'] as String? ?? '',
  address: d['address'] as String? ?? '',
  phone: d['phone'] as String? ?? '',
  date: (d['date'] as Timestamp).toDate(),
  productId: d['productId'] as String? ?? '',
  productName: d['productName'] as String? ?? '',
  imageUrl: d['imageUrl'] as String? ?? '',
  unit: d['unit'] as String? ?? '',
  quantity: (d['quantity'] as num).toInt(),
  unitPrice: (d['unitPrice'] as num).toDouble(),
);

Map<String, dynamic> saleToMap(SaleUiModel s) => {
  'customerName': s.customerName,
  'address': s.address,
  'phone': s.phone,
  'date': Timestamp.fromDate(s.date),
  'productId': s.productId,
  'productName': s.productName,
  'imageUrl': s.imageUrl,
  'unit': s.unit,
  'quantity': s.quantity,
  'unitPrice': s.unitPrice,
};
