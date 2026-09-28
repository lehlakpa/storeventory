import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/data/firestore_codec.dart';
import 'package:storeventory/models/product_ui_model.dart';

void main() {
  test(
    'sale persists a receipt, decreases stock and appends immutable history',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin');
      const p = ProductUiModel(
        id: 'test-product',
        name: 'Test product',
        imageUrl: '',
        price: 80,
        quantity: 5,
        category: 'Test',
      );
      await repo.save(p);
      final date = DateTime(2026, 9, 28);
      final sale = await repo.recordSale(
        p.id,
        2,
        customerName: ' Customer ',
        address: ' Address ',
        phone: '9800000000',
        date: date,
      );
      expect(
        (await db.collection('products').doc(p.id).get()).data()!['quantity'],
        3,
      );
      final stored = await db.collection('sales').doc(sale.id).get();
      final receipt = saleFromMap(stored.id, stored.data()!);
      expect(receipt.customerName, 'Customer');
      expect(receipt.date, date);
      expect(receipt.totalAmount, 160);
      expect((await db.collection('stock_history').get()).docs.length, 2);
      await repo.remove(p.id);
      expect((await db.collection('sales').doc(sale.id).get()).exists, isTrue);
      expect(receipt.receiptText, contains('Total: Ns 160.00'));
      expect(receipt.productName, p.name);
    },
  );
  test(
    'overselling and invalid sale leave inventory and receipts unchanged',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin');
      await repo.save(
        const ProductUiModel(
          id: 'p',
          name: 'Test',
          imageUrl: '',
          price: 1,
          quantity: 1,
          category: 'Test',
        ),
      );
      for (final quantity in [0, 2]) {
        await expectLater(
          repo.recordSale(
            'p',
            quantity,
            customerName: 'A',
            address: 'B',
            phone: '1234567',
            date: DateTime.now(),
          ),
          throwsStateError,
        );
      }
      expect((await db.collection('sales').get()).docs, isEmpty);
      expect(
        (await db.collection('products').doc('p').get()).data()!['quantity'],
        1,
      );
      expect((await db.collection('stock_history').get()).docs.length, 1);
    },
  );
}
