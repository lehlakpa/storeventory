import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storeventory/blocs/inventory_cubit.dart';
import 'package:storeventory/core/theme/app_theme.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/models/product_ui_model.dart';
import 'package:storeventory/screens/stocks/product_details_screen.dart';

void main() {
  testWidgets('details update validates quantity and saves stock with note', (
    tester,
  ) async {
    final repo = FirestoreInventoryRepository(FakeFirebaseFirestore(), 'admin');
    await repo.save(
      const ProductUiModel(
        id: 'rice',
        name: 'Rice',
        imageUrl: '',
        price: 20,
        quantity: 5,
        category: 'Food',
        note: 'Keep dry',
      ),
    );
    final cubit = InventoryCubit(repo);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProductDetailsScreen(productId: 'rice'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Update Stock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update Stock'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), '-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Update Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number of 0 or more'), findsOneWidget);
    await tester.enterText(fields.at(0), '12');
    await tester.enterText(fields.at(1), 'Fresh delivery');
    await tester.tap(find.widgetWithText(FilledButton, 'Update Stock'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(cubit.product('rice')!.quantity, 12);
    expect(cubit.product('rice')!.note, 'Fresh delivery');
    await tester.ensureVisible(find.text('Fresh delivery'));
    expect(find.text('Fresh delivery'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => cubit.close());
  });
}
