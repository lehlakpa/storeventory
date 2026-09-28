import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/models/product_ui_model.dart';
import 'package:storeventory/data/firestore_codec.dart';

void main() {
  test(
    'product notes persist, survive stock changes, and can be cleared',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin');
      const product = ProductUiModel(
        id: 'noted',
        name: 'Rice',
        imageUrl: '',
        price: 20,
        quantity: 5,
        category: 'Food',
        note: 'Keep dry',
      );
      expect(productFromMap('legacy', {}).note, isEmpty);
      expect(product.withQuantity(8).note, 'Keep dry');
      await repo.save(product);
      expect((await repo.watchProducts().first).single.note, 'Keep dry');
      await repo.changeStock(product.id, 2, increment: true);
      var saved = (await repo.watchProducts().first).single;
      expect(saved.quantity, 7);
      expect(saved.note, 'Keep dry');
      await repo.changeStock(product.id, 4, note: '  New delivery  ');
      saved = (await repo.watchProducts().first).single;
      expect(saved.quantity, 4);
      expect(saved.note, 'New delivery');
      await repo.save(saved.withQuantity(6), previous: saved);
      expect((await repo.watchProducts().first).single.note, 'New delivery');
      await repo.changeStock(product.id, 6, note: '');
      expect((await repo.watchProducts().first).single.note, isEmpty);
    },
  );

  test(
    'restocks use current server stock and stale edits cannot overwrite it',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin');
      const p = ProductUiModel(
        id: 'p',
        name: 'Test',
        imageUrl: '',
        price: 10,
        quantity: 4,
        category: 'Test',
      );
      await repo.save(p);
      await repo.changeStock('p', 3, increment: true);
      await repo.changeStock('p', 2, increment: true);
      expect(
        (await db.collection('products').doc('p').get()).data()!['quantity'],
        9,
      );
      await expectLater(
        repo.save(p.withQuantity(5), previous: p),
        throwsStateError,
      );
      await repo.changeStock('p', 0);
      expect(
        (await db.collection('products').doc('p').get()).data()!['quantity'],
        0,
      );
      await repo.remove('p');
      expect((await db.collection('products').get()).docs, isEmpty);
      expect((await db.collection('stock_history').get()).docs.length, 5);
    },
  );
  test('categories begin empty and duplicate names are rejected', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreInventoryRepository(db, 'admin');
    expect(await repo.watchCategories().first, isEmpty);
    expect(await repo.addCategory(''), isFalse);
    expect(await repo.addCategory(' Drinks '), isTrue);
    expect(await repo.addCategory('drinks'), isFalse);
    expect(await repo.watchCategories().first, ['Drinks']);
  });
}
