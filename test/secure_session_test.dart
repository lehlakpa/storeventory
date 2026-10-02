import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storeventory/data/auth_repository.dart';
import 'package:storeventory/services/secure_storage_service.dart';

// This test double tracks refresh attempts and simulates token revocation.
// ignore: must_be_immutable
class RefreshUser extends MockUser {
  RefreshUser(this.authenticatedAt)
    : super(
        uid: 'admin',
        email: 'test@example.com',
        refreshToken: 'test-refresh',
      );
  DateTime authenticatedAt;
  DateTime? nextAuthentication;
  bool failReauthentication = false;
  int refreshes = 0;
  bool failRefresh = false;
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    if (forceRefresh) refreshes++;
    if (failRefresh) {
      throw FirebaseAuthException(code: 'user-token-expired');
    }
    return Future.value(SessionToken(authenticatedAt));
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential? credential,
  ) async {
    if (failReauthentication) {
      throw FirebaseAuthException(code: 'wrong-password');
    }
    authenticatedAt = nextAuthentication ?? authenticatedAt;
    return super.reauthenticateWithCredential(credential);
  }
}

class SessionToken implements IdTokenResult {
  SessionToken(this.authTime);
  @override
  final DateTime authTime;
  @override
  String get token => 'fake_token';
  @override
  DateTime get expirationTime => authTime.add(const Duration(hours: 1));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingStorage extends SecureStorageService {
  @override
  Future<void> saveSession(Map<String, dynamic> session) async {
    throw StateError('Storage unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = SecureStorageService();
  late DateTime now;
  late RefreshUser user;
  late MockFirebaseAuth auth;
  late FirebaseAuthRepository repo;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 9, 29);
    user = RefreshUser(now);
    auth = MockFirebaseAuth(mockUser: user);
    repo = FirebaseAuthRepository(
      auth,
      FakeFirebaseFirestore(),
      now: () => now,
    );
  });

  Future<void> login() async {
    user.authenticatedAt = now;
    await repo.login('test@example.com', 'password123');
  }

  test(
    'login stores separate token and fixed 30-day session deadlines',
    () async {
      await login();
      final saved = (await storage.readSession())!;
      expect(saved['uid'], 'admin');
      expect(saved['access_token'], 'fake_token');
      expect(saved['refresh_token'], 'test-refresh');
      expect(
        saved['session_expires_at'],
        now.add(const Duration(days: 30)).toIso8601String(),
      );
      expect(
        saved['access_token_expires_at'],
        isNot(saved['session_expires_at']),
      );
      expect(saved.containsKey('password'), isFalse);
      expect(user.refreshes, 1);
    },
  );

  test(
    'biometric re-entry refreshes tokens without extending the deadline',
    () async {
      await login();
      final originalDeadline = repo.sessionExpiresAt;
      now = now.add(const Duration(days: 29));
      await repo.unlockSession('admin');
      expect(user.refreshes, 2);
      expect(repo.sessionExpiresAt, originalDeadline);
      expect(
        (await storage.readSession())!['session_expires_at'],
        repo.sessionExpiresAt!.toIso8601String(),
      );
    },
  );

  test('session expires at exactly 30 days and cannot refresh', () async {
    await login();
    now = now.add(const Duration(days: 30));
    await expectLater(
      repo.unlockSession('admin'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(user.refreshes, 1);
    expect(auth.currentUser, isNull);
    expect(await storage.readSession(), isNull);
  });

  test('logout clears tokens but preserves appearance preference', () async {
    await login();
    await SecureStorageService.storage.write(key: 'theme_mode', value: 'dark');
    await repo.logout();
    expect(await storage.readSession(), isNull);
    expect(await SecureStorageService.storage.read(key: 'theme_mode'), 'dark');
    expect(auth.currentUser, isNull);
  });

  test('a new password login starts a new 30-day deadline', () async {
    await login();
    now = now.add(const Duration(hours: 12));
    await login();
    expect(user.refreshes, 2);
    expect(repo.sessionExpiresAt, now.add(const Duration(days: 30)));
  });

  test(
    'a saved token for a different account cannot unlock this account',
    () async {
      await login();
      final saved = (await storage.readSession())!;
      saved['uid'] = 'another-account';
      await storage.saveSession(saved);
      await expectLater(
        repo.unlockSession('admin'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(auth.currentUser, isNull);
      expect(await storage.readSession(), isNull);
    },
  );

  test('corrupt stored data fails closed', () async {
    await login();
    await SecureStorageService.storage.write(
      key: SecureStorageService.sessionKey,
      value: 'broken-json',
    );
    await expectLater(
      repo.unlockSession('admin'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(auth.currentUser, isNull);
    expect(await storage.readSession(), isNull);
  });

  test('revoked refresh token clears the session', () async {
    await login();
    user.failRefresh = true;
    await expectLater(
      repo.unlockSession('admin'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(await storage.readSession(), isNull);
    expect(auth.currentUser, isNull);
  });

  test(
    'repeated biometric unlocks retain the original server deadline',
    () async {
      await login();
      final deadline = repo.sessionExpiresAt;
      for (var day = 0; day < 29; day++) {
        now = now.add(const Duration(days: 1));
        await repo.unlockSession('admin');
        expect(repo.sessionExpiresAt, deadline);
      }
      now = deadline!;
      await expectLater(
        repo.unlockSession('admin'),
        throwsA(isA<FirebaseAuthException>()),
      );
    },
  );

  test(
    'tampering with local expiry cannot extend the server deadline',
    () async {
      await login();
      final saved = (await storage.readSession())!;
      saved['session_expires_at'] = now
          .add(const Duration(days: 90))
          .toIso8601String();
      await storage.saveSession(saved);
      now = now.add(const Duration(days: 30));
      await expectLater(
        repo.unlockSession('admin'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(auth.currentUser, isNull);
    },
  );

  test(
    'backend revocation blocks unlock even while refresh token still works',
    () async {
      await login();
      await repo.db.collection('session_controls').doc('admin').set({
        'revokedBefore': now.millisecondsSinceEpoch ~/ 1000,
      });
      await expectLater(
        repo.unlockSession('admin'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(auth.currentUser, isNull);
      expect(await storage.readSession(), isNull);
    },
  );

  test('backend disabling prevents a new password login', () async {
    await repo.db.collection('session_controls').doc('admin').set({
      'disabled': true,
    });
    await expectLater(login(), throwsA(isA<FirebaseAuthException>()));
    expect(auth.currentUser, isNull);
  });

  test(
    'password verification preserves expiry on both client and server',
    () async {
      await login();
      final deadline = repo.sessionExpiresAt;
      now = now.add(const Duration(days: 20));
      user.nextAuthentication = now;
      await repo.reauthenticate('password123');
      expect(repo.sessionExpiresAt, deadline);
      final server = await repo.db
          .collection('auth_sessions')
          .doc('admin')
          .collection('sessions')
          .doc('${now.millisecondsSinceEpoch ~/ 1000}')
          .get();
      expect(
        (server.data()!['expiresAt'] as Timestamp).toDate().toUtc(),
        deadline,
      );
      expect((await storage.readSession())!.containsKey('password'), isFalse);
    },
  );

  test('incorrect password cannot authorize a sensitive action', () async {
    await login();
    final before = await storage.readSession();
    user.failReauthentication = true;
    await expectLater(
      repo.reauthenticate('wrong'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(await storage.readSession(), before);
    expect(user.refreshes, 1);
  });

  test('live backend revocation signs out an open session', () async {
    await login();
    final events = <String?>[];
    final subscription = repo.sessions.listen(events.add);
    await Future<void>.delayed(Duration.zero);
    await repo.db.collection('session_controls').doc('admin').set({
      'disabled': true,
    });
    for (var i = 0; i < 20 && auth.currentUser != null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(auth.currentUser, isNull);
    await subscription.cancel();
  });

  test('failed secure write does not leave a signed-in account', () async {
    repo = FirebaseAuthRepository(
      auth,
      FakeFirebaseFirestore(),
      storage: FailingStorage(),
      now: () => now,
    );
    await expectLater(login(), throwsStateError);
    expect(auth.currentUser, isNull);
  });

  test(
    'legacy preferences migrate while plaintext tokens are removed',
    () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'has_seen_onboarding': true,
        'access_token': 'old-demo-token',
        'biometric_enabled': true,
      });
      await storage.migrateLegacyPreferences();
      expect(
        await SecureStorageService.storage.read(key: 'theme_mode'),
        'dark',
      );
      expect(
        await SecureStorageService.storage.read(key: 'has_seen_onboarding'),
        'true',
      );
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      expect(await storage.readSession(), isNull);
    },
  );
}
