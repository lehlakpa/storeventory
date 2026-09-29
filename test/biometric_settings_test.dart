import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storeventory/blocs/auth_bloc.dart';
import 'package:storeventory/services/biometric_service.dart';
import 'package:storeventory/widgets/biometric_settings_tile.dart';

import 'support/test_auth_repository.dart';
import 'support/test_biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestAuthRepository repo;
  late TestBiometricService biometrics;
  late AuthBloc auth;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    repo = TestAuthRepository();
    biometrics = TestBiometricService()..enabled = false;
    auth = AuthBloc(repo, biometrics: biometrics);
    await auth.stream.firstWhere((s) => !s.initializing);
    await auth.authenticate(
      () => repo.login('test@example.com', 'password123'),
    );
  });
  tearDown(() async {
    await auth.close();
    await repo.changes.close();
  });
  Future<void> showSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: const MaterialApp(
          home: Scaffold(body: BiometricSettingsTile(uid: 'test-user')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('enable waits for verification and then persists the switch', (
    tester,
  ) async {
    biometrics.gate = Completer<bool>();
    await showSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(biometrics.preferences, isEmpty);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
    biometrics.gate!.complete(true);
    await tester.pumpAndSettle();
    expect(biometrics.calls, 1);
    expect(biometrics.preferences['test-user'], isTrue);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.text('Fingerprint login enabled.'), findsOneWidget);
  });

  testWidgets('cancelled scan leaves fingerprint disabled', (tester) async {
    biometrics.accepted = false;
    await showSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(biometrics.preferences, isEmpty);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.textContaining('remains disabled'), findsOneWidget);
  });

  testWidgets('unavailable biometrics do not enable or start a scan', (
    tester,
  ) async {
    biometrics.available = false;
    await showSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(biometrics.calls, 0);
    expect(biometrics.preferences, isEmpty);
    expect(find.textContaining('No biometrics are available'), findsOneWidget);
  });

  testWidgets('disable saves immediately without a scan', (tester) async {
    biometrics.preferences['test-user'] = true;
    await showSettings(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(biometrics.calls, 0);
    expect(biometrics.preferences['test-user'], isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  test('secure preference defaults off and is isolated by account', () async {
    final service = BiometricService();
    expect(await service.isEnabled('first'), isFalse);
    await service.setEnabled('first', true);
    expect(await BiometricService().isEnabled('first'), isTrue);
    expect(await service.isEnabled('second'), isFalse);
    await service.setEnabled('first', false);
    expect(await service.isEnabled('first'), isFalse);
  });
}
