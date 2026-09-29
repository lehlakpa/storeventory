import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
  RefreshUser() : super(uid: 'admin', refreshToken: 'test-refresh');
  int refreshes = 0;
  bool failRefresh = false;
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    if (forceRefresh) refreshes++;
    if (failRefresh) {
      throw FirebaseAuthException(code: 'user-token-expired');
    }
    return super.getIdTokenResult(forceRefresh);
  }
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
    user = RefreshUser();
    auth = MockFirebaseAuth(mockUser: user);
    repo = FirebaseAuthRepository(
      auth,
      FakeFirebaseFirestore(),
      now: () => now,
    );
  });

  Future<void> login() => repo.login('test@example.com', 'password123');

  test(
    'login refreshes and securely stores token with separate 24-hour expiry',
    () async {
      await login();
      final saved = (await storage.readSession())!;
      expect(saved['uid'], 'admin');
      expect(saved['access_token'], 'fake_token');
      expect(saved['refresh_token'], 'test-refresh');
      expect(
        saved['session_expires_at'],
        now.add(const Duration(hours: 24)).toIso8601String(),
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
    'biometric re-entry within 24 hours refreshes and renews the saved session',
    () async {
      await login();
      now = now.add(const Duration(hours: 23));
      await repo.unlockSession('admin');
      expect(user.refreshes, 2);
      expect(repo.sessionExpiresAt, now.add(const Duration(hours: 24)));
      expect(
        (await storage.readSession())!['session_expires_at'],
        repo.sessionExpiresAt!.toIso8601String(),
      );
    },
  );

  test('session expires at exactly 24 hours and cannot refresh', () async {
    await login();
    now = now.add(const Duration(hours: 24));
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

  test(
    'password login again refreshes and replaces the 24-hour deadline',
    () async {
      await login();
      now = now.add(const Duration(hours: 12));
      await login();
      expect(user.refreshes, 2);
      expect(repo.sessionExpiresAt, now.add(const Duration(hours: 24)));
    },
  );

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

  test('failed secure write does not leave a signed-in account', () async {
    repo = FirebaseAuthRepository(
      auth,
      FakeFirebaseFirestore(),
      storage: FailingStorage(),
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
