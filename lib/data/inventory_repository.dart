import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_ui_model.dart';
import '../models/sale_ui_model.dart';
import 'firestore_codec.dart';

abstract class InventoryRepository {
  Stream<List<ProductUiModel>> watchProducts();
  Stream<List<String>> watchCategories();
  Stream<List<SaleUiModel>> watchSales();
  Future<void> save(ProductUiModel product, {ProductUiModel? previous});
  Future<void> remove(String id);
  Future<void> changeStock(String id, int quantity, {bool increment = false});
  Future<bool> addCategory(String name);
  Future<SaleUiModel> recordSale(
    String id,
    int quantity, {
    required String customerName,
    required String address,
    required String phone,
    required DateTime date,
  });
}

class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository(this.db, this.uid);
  final FirebaseFirestore db;
  final String uid;

  @override
  Stream<List<ProductUiModel>> watchProducts() => db
      .collection('products')
      .snapshots()
      .map((s) => s.docs.map((d) => productFromMap(d.id, d.data())).toList());
  @override
  Stream<List<String>> watchCategories() => db
      .collection('categories')
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => d.data()['name'] as String).toSet().toList()
              ..sort(),
      );
  @override
  Stream<List<SaleUiModel>> watchSales() => db
      .collection('sales')
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => saleFromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.date.compareTo(b.date)),
      );

  void _history(
    Transaction t,
    String id,
    int before,
    int after,
    String reason,
  ) {
    t.set(db.collection('stock_history').doc(), {
      'productId': id,
      'previousQuantity': before,
      'quantity': after,
      'change': after - before,
      'reason': reason,
      'adminId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> save(ProductUiModel product, {ProductUiModel? previous}) async {
    final ref = product.id.isEmpty
        ? db.collection('products').doc()
        : db.collection('products').doc(product.id);
    await db.runTransaction((t) async {
      final snapshot = await t.get(ref);
      if (previous != null && !snapshot.exists) {
        throw StateError('Product was deleted.');
      }
      final current = snapshot.exists
          ? productFromMap(ref.id, snapshot.data()!)
          : null;
      if (previous != null && current?.quantity != previous.quantity) {
        throw StateError('Stock changed. Reopen the product before editing.');
      }
      t.set(ref, productToMap(product));
      if (current == null || current.quantity != product.quantity) {
        _history(
          t,
          ref.id,
          current?.quantity ?? 0,
          product.quantity,
          current == null ? 'created' : 'edited',
        );
      }
    });
  }

  @override
  Future<void> changeStock(
    String id,
    int quantity, {
    bool increment = false,
  }) async {
    if (quantity < 0) throw StateError('Quantity cannot be negative.');
    final ref = db.collection('products').doc(id);
    await db.runTransaction((t) async {
      final s = await t.get(ref);
      if (!s.exists) throw StateError('Product no longer available.');
      final before = (s.data()!['quantity'] as num).toInt();
      final after = increment ? before + quantity : quantity;
      t.update(ref, {'quantity': after});
      _history(t, id, before, after, increment ? 'restocked' : 'adjusted');
    });
  }

  @override
  Future<void> remove(String id) async {
    final ref = db.collection('products').doc(id);
    await db.runTransaction((t) async {
      final s = await t.get(ref);
      if (!s.exists) return;
      _history(t, id, (s.data()!['quantity'] as num).toInt(), 0, 'deleted');
      t.delete(ref);
    });
  }

  @override
  Future<bool> addCategory(String name) async {
    final value = name.trim();
    if (value.isEmpty) return false;
    final ref = db
        .collection('categories')
        .doc(Uri.encodeComponent(value.toLowerCase()));
    return db.runTransaction((t) async {
      final s = await t.get(ref);
      if (s.exists) return false;
      t.set(ref, {'name': value, 'createdAt': FieldValue.serverTimestamp()});
      return true;
    });
  }

  @override
  Future<SaleUiModel> recordSale(
    String id,
    int quantity, {
    required String customerName,
    required String address,
    required String phone,
    required DateTime date,
  }) async {
    if (quantity <= 0 ||
        customerName.trim().isEmpty ||
        address.trim().isEmpty ||
        phone.trim().isEmpty) {
      throw StateError('Enter valid customer and sale details.');
    }
    final productRef = db.collection('products').doc(id);
    final saleRef = db.collection('sales').doc();
    return db.runTransaction((t) async {
      final snapshot = await t.get(productRef);
      if (!snapshot.exists) throw StateError('Product no longer available.');
      final p = productFromMap(id, snapshot.data()!);
      if (p.quantity < quantity) {
        throw StateError('Not enough stock available.');
      }
      final sale = SaleUiModel(
        id: saleRef.id,
        customerName: customerName.trim(),
        address: address.trim(),
        phone: phone.trim(),
        date: date,
        productId: id,
        productName: p.name,
        imageUrl: p.imageUrl,
        unit: p.unit,
        quantity: quantity,
        unitPrice: p.price,
      );
      t.set(saleRef, {
        ...saleToMap(sale),
        'adminId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      t.update(productRef, {'quantity': p.quantity - quantity});
      _history(t, id, p.quantity, p.quantity - quantity, 'sale');
      return sale;
    });
  }
}
