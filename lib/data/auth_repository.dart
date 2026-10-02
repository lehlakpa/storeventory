import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/secure_storage_service.dart';

class AdminProfile {
  const AdminProfile({
    required this.uid,
    required this.email,
    required this.name,
  });
  final String uid, email, name;
}

abstract class AuthRepository {
  Stream<String?> get sessions;
  Future<AdminProfile> profile(String uid);
  Future<AdminProfile> login(String email, String password);
  Future<AdminProfile> register(String name, String email, String password);
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<AdminProfile> unlockSession(String uid);
  Future<void> reauthenticate(String password);
  DateTime? get sessionExpiresAt;
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this.auth,
    this.db, {
    SecureStorageService? storage,
    DateTime Function()? now,
  }) : storage = storage ?? const SecureStorageService(),
       now = now ?? DateTime.now;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final SecureStorageService storage;
  final DateTime Function() now;
  @override
  DateTime? sessionExpiresAt;

  Future<void> _saveFreshSession(
    User user, {
    DateTime? deadline,
    bool createSession = true,
  }) async {
    // The Firebase SDK uses its refresh token; ID token expiry remains server-owned.
    final result = await user.getIdTokenResult(true);
    if (auth.currentUser?.uid != user.uid ||
        result.token == null ||
        result.expirationTime == null ||
        result.authTime == null) {
      throw StateError('Unable to refresh the current session.');
    }
    final tokenDeadline = result.authTime!.toUtc().add(
      const Duration(days: 30),
    );
    var expires = deadline != null && deadline.isBefore(tokenDeadline)
        ? deadline
        : tokenDeadline;
    if (!now().toUtc().isBefore(expires)) {
      throw FirebaseAuthException(code: 'session-expired');
    }
    // Read from the server: a cached control document cannot authorize unlock.
    final control = await db
        .collection('session_controls')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    final data = control.data();
    if (data?['disabled'] == true) {
      throw FirebaseAuthException(code: 'user-disabled');
    }
    final revokedBefore = data?['revokedBefore'];
    if (revokedBefore is num &&
        result.authTime!.millisecondsSinceEpoch ~/ 1000 <= revokedBefore) {
      throw FirebaseAuthException(code: 'user-token-expired');
    }
    if (auth.currentUser?.uid != user.uid) {
      throw FirebaseAuthException(code: 'invalid-user-token');
    }
    final sessionRef = db
        .collection('auth_sessions')
        .doc(user.uid)
        .collection('sessions')
        .doc('${result.authTime!.millisecondsSinceEpoch ~/ 1000}');
    final session = await sessionRef.get(
      const GetOptions(source: Source.server),
    );
    if (session.exists) {
      final serverExpiry = session.data()?['expiresAt'];
      if (serverExpiry is! Timestamp) {
        throw FirebaseAuthException(code: 'session-expired');
      }
      if (serverExpiry.toDate().isBefore(expires)) {
        expires = serverExpiry.toDate().toUtc();
      }
    } else if (createSession) {
      await sessionRef.set({'expiresAt': Timestamp.fromDate(expires)});
    } else {
      throw FirebaseAuthException(code: 'session-expired');
    }
    if (!now().toUtc().isBefore(expires)) {
      throw FirebaseAuthException(code: 'session-expired');
    }
    await storage.saveSession({
      'uid': user.uid,
      'access_token': result.token,
      if (user.refreshToken != null) 'refresh_token': user.refreshToken,
      'access_token_expires_at': result.expirationTime!
          .toUtc()
          .toIso8601String(),
      'session_expires_at': expires.toIso8601String(),
    });
    sessionExpiresAt = expires;
  }

  @override
  Future<AdminProfile> unlockSession(String uid) async {
    final saved = await storage.readSession();
    final rawExpiry = saved?['session_expires_at'];
    final expires = rawExpiry is String ? DateTime.tryParse(rawExpiry) : null;
    if (saved?['uid'] != uid ||
        auth.currentUser?.uid != uid ||
        expires == null ||
        !now().toUtc().isBefore(expires)) {
      await logout();
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'Your 30-day session expired. Sign in with your password.',
      );
    }
    try {
      await _saveFreshSession(
        auth.currentUser!,
        deadline: expires,
        createSession: false,
      );
      final admin = await profile(uid);
      return admin;
    } on FirebaseAuthException catch (e) {
      if ([
        'user-disabled',
        'user-token-expired',
        'invalid-user-token',
        'user-not-found',
        'session-expired',
      ].contains(e.code)) {
        await logout();
      }
      rethrow;
    }
  }

  @override
  Future<void> reauthenticate(String password) async {
    final user = auth.currentUser;
    if (user == null ||
        user.email == null ||
        sessionExpiresAt == null ||
        !now().toUtc().isBefore(sessionExpiresAt!)) {
      await logout();
      throw FirebaseAuthException(code: 'session-expired');
    }
    final deadline = sessionExpiresAt!;
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
      // Password verification allows a sensitive action but does not slide the
      // app's original login deadline.
      await _saveFreshSession(user, deadline: deadline);
    } on FirebaseAuthException catch (e) {
      if ([
        'user-disabled',
        'user-token-expired',
        'invalid-user-token',
        'user-not-found',
        'session-expired',
      ].contains(e.code)) {
        await logout();
      }
      rethrow;
    }
  }

  @override
  Stream<String?> get sessions => Stream<String?>.multi((controller) {
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? controls;
    var revision = 0;
    final authSubscription = auth.authStateChanges().listen((user) async {
      final currentRevision = ++revision;
      await controls?.cancel();
      if (currentRevision != revision) return;
      controller.add(user?.uid);
      if (user == null) return;
      controls = db
          .collection('session_controls')
          .doc(user.uid)
          .snapshots()
          .listen(
            (snapshot) async {
              try {
                final data = snapshot.data();
                if (data == null) return;
                final token = await user.getIdTokenResult();
                if (currentRevision != revision ||
                    auth.currentUser?.uid != user.uid) {
                  return;
                }
                final cutoff = data['revokedBefore'];
                if (data['disabled'] == true ||
                    (cutoff is num &&
                        token.authTime != null &&
                        token.authTime!.millisecondsSinceEpoch ~/ 1000 <=
                            cutoff)) {
                  await logout();
                }
              } catch (e, stack) {
                if (currentRevision == revision) controller.addError(e, stack);
              }
            },
            onError: (Object e, StackTrace stack) {
              if (currentRevision == revision) controller.addError(e, stack);
            },
          );
    }, onError: controller.addError);
    controller.onCancel = () async {
      ++revision;
      await authSubscription.cancel();
      await controls?.cancel();
    };
  });
  @override
  Future<AdminProfile> profile(String uid) async {
    final doc = await db
        .collection('admins')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (auth.currentUser?.uid != uid) {
      throw FirebaseAuthException(code: 'invalid-user-token');
    }
    var data = doc.data();
    if (data == null) {
      final user = auth.currentUser;
      if (user == null || user.uid != uid) {
        throw StateError('Session changed. Sign in again.');
      }
      data = {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await doc.reference.set(data);
    }
    return AdminProfile(
      uid: uid,
      email: data['email'] as String? ?? auth.currentUser?.email ?? '',
      name: data['name'] as String? ?? auth.currentUser?.displayName ?? '',
    );
  }

  @override
  Future<AdminProfile> login(String email, String password) async {
    final result = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      await _saveFreshSession(result.user!);
      final admin = await profile(result.user!.uid);
      return admin;
    } catch (_) {
      await logout();
      rethrow;
    }
  }

  @override
  Future<AdminProfile> register(
    String name,
    String email,
    String password,
  ) async {
    final result = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user!;
    try {
      await _saveFreshSession(user);
      await user.updateDisplayName(name.trim());
      await db.collection('admins').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      final admin = await profile(user.uid);
      return admin;
    } catch (_) {
      await logout();
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'profile-creation-failed',
        message: 'Your account was created, but the profile could not be saved. Sign in again to retry.',
      );
    }
  }

  @override
  Future<void> logout() async {
    sessionExpiresAt = null;
    try {
      await auth.signOut();
    } finally {
      await storage.clearSession();
    }
  }

  @override
  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
}
