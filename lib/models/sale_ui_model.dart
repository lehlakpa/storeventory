/// A receipt keeps the values at the time of sale, even if a product changes.
class SaleUiModel {
  const SaleUiModel({
    required this.id,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.date,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String customerName;
  final String address;
  final String phone;
  final DateTime date;
  final String productId;
  final String productName;
  final String imageUrl;
  final String unit;
  final int quantity;
  final double unitPrice;

  bool matchesSearch(String query) {
    final value = query.trim().toLowerCase();
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return value.isEmpty ||
        customerName.toLowerCase().contains(value) ||
        id.toLowerCase().contains(
          value.startsWith('#') ? value.substring(1) : value,
        ) ||
        phone.toLowerCase().contains(value) ||
        (digits.isNotEmpty &&
            RegExp(r'^[+0-9 ()-]+$').hasMatch(value) &&
            phone.replaceAll(RegExp(r'\D'), '').contains(digits));
  }

  double get totalAmount => quantity * unitPrice;
  String get formattedDate =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String get receiptText =>
      '''STOREVENTORY
Sales Receipt #$id
Date: $formattedDate

Customer: $customerName
Address: $address
Phone: $phone

$productName
$quantity $unit x Ns ${unitPrice.toStringAsFixed(2)}
Total: Ns ${totalAmount.toStringAsFixed(2)}

Thank you for your purchase!''';
}
