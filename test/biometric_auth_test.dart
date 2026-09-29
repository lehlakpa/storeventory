import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:storeventory/blocs/auth_bloc.dart';
import 'package:storeventory/blocs/auth_event.dart';
import 'package:storeventory/blocs/auth_state.dart';

import 'support/test_auth_repository.dart';
import 'support/test_biometric_service.dart';

void main() {
  late TestAuthRepository repo;
  late TestBiometricService biometrics;
  late AuthBloc bloc;

  setUp(() async {
    repo = TestAuthRepository()..currentUid = 'test-user';
    biometrics = TestBiometricService();
    bloc = AuthBloc(repo, biometrics: biometrics);
    await bloc.stream.firstWhere((s) => !s.initializing);
  });
  tearDown(() async {
    await bloc.close();
    await repo.changes.close();
  });

  Future<AuthState> unlock() {
    final result = bloc.stream.firstWhere((s) => !s.busy);
    bloc.add(BiometricLoginRequested());
    return result;
  }

  test('restored session stays locked until biometric success', () async {
    expect(bloc.state.profile, isNull);
    expect((await unlock()).profile?.uid, 'test-user');
    expect(repo.loginCalls, 0);
  });
  test('cancellation leaves password fallback available', () async {
    biometrics.accepted = false;
    expect((await unlock()).profile, isNull);
    final signedIn = bloc.stream.firstWhere((s) => s.profile != null);
    unawaited(
      bloc.authenticate(() => repo.login('test@example.com', 'password123')),
    );
    await signedIn;
    expect(repo.loginCalls, 1);
  });
  test('unavailable biometrics never start a prompt', () async {
    biometrics.available = false;
    final state = await unlock();
    expect(state.profile, isNull);
    expect(state.error, contains('unavailable'));
    expect(biometrics.calls, 0);
  });

  test(
    'an open account logs out when its session deadline is reached',
    () async {
      repo.sessionExpiresAt = DateTime.now().subtract(
        const Duration(seconds: 1),
      );
      await unlock();
      await bloc.stream.firstWhere((s) => !s.busy && s.profile == null);
      expect(repo.currentUid, isNull);
    },
  );
  test('logout prevents biometric access to the old session', () async {
    await unlock();
    final signedOut = bloc.stream.firstWhere(
      (s) => !s.busy && s.profile == null,
    );
    bloc.add(LogoutRequested());
    await signedOut;
    expect((await unlock()).error, contains('email and password first'));
    expect(biometrics.calls, 1);
  });
  test(
    'duplicate requests and session changes cannot bypass the lock',
    () async {
      biometrics.gate = Completer<bool>();
      final busy = bloc.stream.firstWhere((s) => s.busy);
      bloc.add(BiometricLoginRequested());
      await busy;
      bloc.add(BiometricLoginRequested());
      repo.changes.add('different-user');
      await Future<void>.delayed(Duration.zero);
      final done = bloc.stream.firstWhere((s) => !s.busy);
      biometrics.gate!.complete(true);
      expect((await done).profile, isNull);
      expect(biometrics.calls, 1);
    },
  );
}
