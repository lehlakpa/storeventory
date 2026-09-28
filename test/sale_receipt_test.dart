import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/data/firestore_codec.dart';
import 'package:storeventory/models/product_ui_model.dart';
import 'package:storeventory/models/sale_ui_model.dart';

void main() {
  test(
    'editing and deleting receipts reconciles stock and preserves pricing',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin');
      await repo.save(
        const ProductUiModel(
          id: 'p',
          name: 'Test',
          imageUrl: '',
          price: 80,
          quantity: 5,
          category: 'Test',
        ),
      );
      final original = await repo.recordSale(
        'p',
        2,
        customerName: 'Alice',
        address: 'Home',
        phone: '+977 980-000-0000',
        date: DateTime(2026, 9, 28),
      );
      SaleUiModel change(int quantity) => SaleUiModel(
        id: original.id,
        customerName: ' Bob ',
        address: ' New address ',
        phone: '9800000001',
        date: DateTime.now(),
        productId: 'ignored',
        productName: 'ignored',
        imageUrl: '',
        unit: 'ignored',
        quantity: quantity,
        unitPrice: 999,
      );
      final updated = await repo.updateSale(change(4));
      expect(updated.customerName, 'Bob');
      expect(updated.totalAmount, 320);
      expect(updated.date, original.date);
      expect(updated.productId, 'p');
      expect(
        (await db.collection('products').doc('p').get()).data()!['quantity'],
        1,
      );
      await expectLater(repo.updateSale(change(6)), throwsStateError);
      expect(
        (await db.collection('sales').doc(original.id).get())
            .data()!['quantity'],
        4,
      );
      await repo.updateSale(change(1));
      expect(
        (await db.collection('products').doc('p').get()).data()!['quantity'],
        4,
      );
      await repo.deleteSale(original.id);
      await repo.deleteSale(original.id);
      expect((await db.collection('sales').get()).docs, isEmpty);
      expect(
        (await db.collection('products').doc('p').get()).data()!['quantity'],
        5,
      );
      expect((await db.collection('stock_history').get()).docs.length, 5);
      await expectLater(repo.updateSale(change(1)), throwsStateError);
      expect(original.matchesSearch(' ALICE '), isTrue);
      expect(original.matchesSearch('9800000000'), isTrue);
      expect(original.matchesSearch('#${original.id}'), isTrue);
      expect(original.matchesSearch('missing'), isFalse);
    },
  );

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
