import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;
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
    return profile(result.user!.uid);
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
      return await profile(user.uid);
    } catch (_) {
      await auth.signOut();
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'profile-creation-failed',
        message: 'Your account was created, but the profile could not be saved. Sign in again to retry.',
      );
    }
  }

  @override
  Future<void> logout() => auth.signOut();
  @override
  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
}
