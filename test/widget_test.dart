import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:storeventory/services/secure_storage_service.dart';
import 'package:storeventory/app.dart';
import 'package:storeventory/data/inventory_repository.dart';
import 'package:storeventory/screens/auth/login_screen.dart';
import 'package:storeventory/screens/main/main_screen.dart';
import 'package:storeventory/widgets/custom_bottom_nav_bar.dart';
import 'package:storeventory/screens/settings/profile_screen.dart';
import 'package:storeventory/screens/settings/about_screen.dart';

import 'support/test_auth_repository.dart';
import 'support/test_biometric_service.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('profile, about and persistent appearance settings', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final auth = TestAuthRepository()..currentUid = 'test-user';
    final repo = FirestoreInventoryRepository(
      FakeFirebaseFirestore(),
      'test-user',
    );
    await tester.pumpWidget(
      App(
        authRepository: auth,
        inventoryRepository: repo,
        hasSeenOnboarding: true,
        biometrics: TestBiometricService(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsNothing);
    await tester.ensureVisible(find.text('Login with biometrics'));
    await tester.tap(find.text('Login with biometrics'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CustomBottomNavBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
    expect(await SecureStorageService.storage.read(key: 'theme_mode'), 'dark');
    await tester.tap(find.text('About Storeventory'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test User'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      App(
        authRepository: auth,
        inventoryRepository: repo,
        hasSeenOnboarding: true,
        biometrics: TestBiometricService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Login with biometrics'));
    await tester.tap(find.text('Login with biometrics'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(CustomBottomNavBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light mode'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.light,
    );
    expect(await SecureStorageService.storage.read(key: 'theme_mode'), 'light');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });

  testWidgets('onboarding, validated auth, empty data and logout', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
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
    expect(find.text('Welcome back! You are signed in.'), findsOneWidget);
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
    expect(find.text('Logout'), findsNothing);
    await tester.tap(find.text('Test User'));
    await tester.pumpAndSettle();
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
      find.text('We could not complete your request. Please try again.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await auth.changes.close();
  });
}
