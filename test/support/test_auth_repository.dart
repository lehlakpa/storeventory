import 'dart:async';

import 'package:storeventory/data/auth_repository.dart';

class TestAuthRepository implements AuthRepository {
  final changes = StreamController<String?>.broadcast();
  String? currentUid;
  bool failLogin = false;
  Completer<void>? loginGate;
  int loginCalls = 0;
  int reauthenticationCalls = 0;
  bool failReauthentication = false;
  @override
  Future<void> reauthenticate(String password) async {
    reauthenticationCalls++;
    if (failReauthentication) throw StateError('Authentication failed');
  }

  @override
  DateTime? sessionExpiresAt;
  @override
  Future<AdminProfile> unlockSession(String uid) => profile(uid);
  @override
  Stream<String?> get sessions async* {
    yield currentUid;
    yield* changes.stream;
  }

  @override
  Future<AdminProfile> profile(String uid) async =>
      AdminProfile(uid: uid, email: 'test@example.com', name: 'Test User');
  @override
  Future<AdminProfile> login(String email, String password) async {
    loginCalls++;
    if (loginGate != null) await loginGate!.future;
    if (failLogin) throw StateError('Authentication failed');
    currentUid = 'test-user';
    changes.add(currentUid);
    return profile(currentUid!);
  }

  @override
  Future<AdminProfile> register(String name, String email, String password) =>
      login(email, password);
  @override
  Future<void> logout() async {
    currentUid = null;
    changes.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {}
}
