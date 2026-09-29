import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:storeventory/blocs/auth_bloc.dart';
import 'package:storeventory/blocs/login/login_bloc.dart';
import 'package:storeventory/blocs/login/login_event.dart';
import 'package:storeventory/blocs/register/register_bloc.dart';
import 'package:storeventory/blocs/register/register_event.dart';

import 'support/test_auth_repository.dart';

void main() {
  late TestAuthRepository repo;
  late AuthBloc auth;
  late LoginBloc login;
  late RegisterBloc register;
  setUp(() async {
    repo = TestAuthRepository();
    auth = AuthBloc(repo);
    await auth.stream.firstWhere((s) => !s.initializing);
    login = LoginBloc(auth);
    register = RegisterBloc(auth);
  });
  tearDown(() async {
    await login.close();
    await register.close();
    await auth.close();
    await repo.changes.close();
  });

  test(
    'login handles loading, duplicate submits and session success',
    () async {
      repo.loginGate = Completer<void>();
      final busy = login.stream.firstWhere((s) => s.busy);
      login.add(LoginRequested('test@example.com', 'password123'));
      await busy;
      login.add(LoginRequested('test@example.com', 'password123'));
      await Future<void>.delayed(Duration.zero);
      expect(repo.loginCalls, 1);
      final done = login.stream.firstWhere((s) => s.success);
      repo.loginGate!.complete();
      await done;
      expect(auth.state.profile?.uid, 'test-user');
      expect(register.state.success, isFalse);
    },
  );

  test('register publishes successful authentication', () async {
    final done = register.stream.firstWhere((s) => s.success);
    register.add(RegisterRequested('Admin', 'test@example.com', 'password123'));
    await done;
    expect(auth.state.profile?.uid, 'test-user');
    expect(login.state.success, isFalse);
    expect(
      auth.state.message,
      'Your account is ready. Welcome to Storeventory!',
    );
  });

  test('login failure remains retryable', () async {
    repo.failLogin = true;
    final failed = login.stream.firstWhere((s) => s.error != null);
    login.add(LoginRequested('test@example.com', 'password123'));
    expect((await failed).busy, isFalse);
    expect(auth.state.profile, isNull);
    repo.failLogin = false;
    final done = login.stream.firstWhere((s) => s.success);
    login.add(LoginRequested('test@example.com', 'password123'));
    expect((await done).error, isNull);
  });

  test(
    'register failure does not change login state or expose account data',
    () async {
      repo.failLogin = true;
      final failed = register.stream.firstWhere((s) => s.error != null);
      register.add(
        RegisterRequested('Admin', 'test@example.com', 'password123'),
      );
      expect((await failed).success, isFalse);
      expect(auth.state.profile, isNull);
      expect(login.state.error, isNull);
    },
  );
}
