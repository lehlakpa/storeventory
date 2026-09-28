import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/models/product_ui_model.dart';

void main() {
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
