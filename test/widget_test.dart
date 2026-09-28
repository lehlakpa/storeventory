import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storeventory/app.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/screens/auth/login_screen.dart';
import 'package:storeventory/screens/main/main_screen.dart';
import 'package:storeventory/widgets/custom_bottom_nav_bar.dart';

import 'support/test_auth_repository.dart';

void main() {
  testWidgets('onboarding, validated auth, empty data and logout', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final auth = TestAuthRepository();
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(
      App(
        authRepository: auth,
        inventoryRepository: FirestoreInventoryRepository(db, 'test-user'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manage Your\nStore Easily'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(auth.loginCalls, 0);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);
    expect(
      find.text('No products yet. Add your first product.'),
      findsOneWidget,
    );
    Future<void> nav(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(CustomBottomNavBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await nav('Stocks');
    expect(find.text('No products found'), findsOneWidget);
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    expect(find.text('No categories found'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(CustomBottomNavBar),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No categories yet. Add a category'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await nav('Settings');
    expect(find.text('test@example.com'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsNothing);
    expect((await db.collection('products').get()).docs, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });
  testWidgets('failed login never opens inventory', (tester) async {
    final auth = TestAuthRepository()..failLogin = true;
    await tester.pumpWidget(App(authRepository: auth, hasSeenOnboarding: true));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsNothing);
    expect(
      find.textContaining('Unable to access your account'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });
}
