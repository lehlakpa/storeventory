class ProductUiModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double purchasePrice;
  final int quantity;
  final int minimumStock;
  final String category;
  final String unit;

  const ProductUiModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.category,
    String? status,
    this.purchasePrice = 0,
    this.minimumStock = 0,
    this.unit = 'pieces',
  });

  String get status => quantity == 0
      ? 'Out of Stock'
      : quantity <= minimumStock
      ? 'Low Stock'
      : 'In Stock';

  ProductUiModel withQuantity(int value) => ProductUiModel(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price,
    quantity: value,
    category: category,
    purchasePrice: purchasePrice,
    minimumStock: minimumStock,
    unit: unit,
  );
}
