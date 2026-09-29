import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:storeventory/data/auth_repository.dart';
import 'package:storeventory/blocs/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'support/test_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'registration persists the authenticated admin and logout clears auth',
    () async {
      final auth = MockFirebaseAuth();
      final db = FakeFirebaseFirestore();
      final repo = FirebaseAuthRepository(auth, db);
      final admin = await repo.register(
        ' New Admin ',
        'admin@test.invalid',
        'password123',
      );
      expect(auth.currentUser!.uid, admin.uid);
      final profile = (await db.collection('admins').doc(admin.uid).get())
          .data()!;
      expect(profile['name'], 'New Admin');
      expect(profile['email'], 'admin@test.invalid');
      expect(profile.containsKey('password'), isFalse);
      expect((await db.collection('admins').get()).docs.length, 1);
      await repo.logout();
      expect(auth.currentUser, isNull);
    },
  );
  test(
    'failed profile creation signs out and does not publish an admin',
    () async {
      final auth = MockFirebaseAuth();
      final db = FakeFirebaseFirestore(
        securityRules: '''service cloud.firestore {
      match /databases/{database}/documents { match /admins/{id} { allow read, write: if false; } }
    }''',
      );
      final repo = FirebaseAuthRepository(auth, db);
      await expectLater(
        repo.register('Admin', 'test@example.com', 'password123'),
        throwsException,
      );
      expect(auth.currentUser, isNull);
    },
  );
  test(
    'BLoC suppresses duplicate login and repeated session notifications',
    () async {
      final repo = TestAuthRepository()..loginGate = Completer<void>();
      final bloc = AuthBloc(repo);
      await bloc.stream.firstWhere((s) => !s.initializing);
      final busy = bloc.stream.firstWhere((s) => s.busy);
      unawaited(
        bloc.authenticate(() => repo.login('test@example.com', 'password123')),
      );
      await busy;
      unawaited(
        bloc.authenticate(() => repo.login('test@example.com', 'password123')),
      );
      await Future<void>.delayed(Duration.zero);
      expect(repo.loginCalls, 1);
      final signedIn = bloc.stream.firstWhere((s) => s.profile != null);
      repo.loginGate!.complete();
      await signedIn;
      repo.changes.add('test-user');
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.profile!.uid, 'test-user');
      expect(bloc.state.initializing, isFalse);
      await bloc.close();
      await repo.changes.close();
    },
  );
}
