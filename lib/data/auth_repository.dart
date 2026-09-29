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

  Future<void> _saveFreshSession(User user) async {
    // The Firebase SDK uses its refresh token; ID token expiry remains server-owned.
    final result = await user.getIdTokenResult(true);
    if (auth.currentUser?.uid != user.uid ||
        result.token == null ||
        result.expirationTime == null) {
      throw StateError('Unable to refresh the current session.');
    }
    final expires = now().toUtc().add(const Duration(hours: 24));
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
        message: 'Your 24-hour session expired. Sign in with your password.',
      );
    }
    try {
      final admin = await profile(uid);
      await _saveFreshSession(auth.currentUser!);
      return admin;
    } on FirebaseAuthException catch (e) {
      if ([
        'user-disabled',
        'user-token-expired',
        'invalid-user-token',
        'user-not-found',
      ].contains(e.code)) {
        await logout();
      }
      rethrow;
    }
  }

  @override
  Stream<String?> get sessions => auth.authStateChanges().map((u) => u?.uid);
  @override
  Future<AdminProfile> profile(String uid) async {
    final doc = await db.collection('admins').doc(uid).get();
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
      final admin = await profile(result.user!.uid);
      await _saveFreshSession(result.user!);
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
      await user.updateDisplayName(name.trim());
      await db.collection('admins').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      final admin = await profile(user.uid);
      await _saveFreshSession(user);
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
