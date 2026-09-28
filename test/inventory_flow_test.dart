import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:storeventory/blocs/inventory_cubit.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/models/product_ui_model.dart';

class FailingRepository extends FirestoreInventoryRepository {
  FailingRepository(super.db, super.uid);
  @override
  Stream<List<ProductUiModel>> watchProducts() =>
      Stream.error(StateError('permission-denied'));
}

void main() {
  test(
    'empty Firestore emits empty lists and zero totals, then live updates',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin');
      final cubit = InventoryCubit(repo);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((s) => !s.loading);
      expect(cubit.products, isEmpty);
      expect(cubit.categories, isEmpty);
      expect(cubit.sales, isEmpty);
      expect(cubit.totalStock, 0);
      expect(cubit.totalValue, 0);
      final update = cubit.stream.firstWhere((s) => s.products.isNotEmpty);
      await repo.save(
        const ProductUiModel(
          id: 'p',
          name: 'Test',
          imageUrl: '',
          price: 5,
          quantity: 2,
          category: 'Test',
        ),
      );
      await update;
      expect(cubit.totalStock, 2);
      expect(cubit.totalValue, 10);
      final removed = cubit.stream.firstWhere((s) => s.products.isEmpty);
      await repo.remove('p');
      await removed;
      expect(cubit.products, isEmpty);
    },
  );
  test('read errors are explicit and are not an empty success', () async {
    final cubit = InventoryCubit(
      FailingRepository(FakeFirebaseFirestore(), 'admin'),
    );
    addTearDown(cubit.close);
    final state = await cubit.stream.firstWhere((s) => s.error != null);
    expect(state.loading, isFalse);
    expect(state.error, contains('Unable to load products'));
  });
  test('closing the session cancels subscriptions', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreInventoryRepository(db, 'admin');
    final cubit = InventoryCubit(repo);
    await cubit.stream.firstWhere((s) => !s.loading);
    await cubit.close();
    await repo.addCategory('Test');
    expect(cubit.isClosed, isTrue);
    expect(cubit.categories, isEmpty);
  });
}
