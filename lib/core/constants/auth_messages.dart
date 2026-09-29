import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

class AuthMessages {
  static const loginSuccess = 'Welcome back! You are signed in.';
  static const registerSuccess =
      'Your account is ready. Welcome to Storeventory!';
  static const biometricSuccess = 'Identity verified. Welcome back!';
  static const sessionExpired =
      'Your session has expired. Sign in with your password to continue.';

  static String error(Object error) {
    if (error is PlatformException) {
      return 'We could not access secure storage on this device. Unlock your device and try again.';
    }
    if (error is! FirebaseException) {
      return 'We could not complete your request. Please try again.';
    }
    return switch (error.code) {
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'wrong-password' ||
      'user-not-found' =>
        'The email or password is incorrect. Check your details and try again.',
      'invalid-email' =>
        'Enter a valid email address, such as name@example.com.',
      'email-already-in-use' => 'An account already uses this email. Sign in with it or use a different email.',
      'weak-password' =>
        'Choose a stronger password with at least 6 characters.',
      'user-disabled' =>
        'This account has been disabled. Contact support for help.',
      'too-many-requests' =>
        'Too many attempts. Wait a few minutes, then try again.',
      'network-request-failed' || 'unavailable' =>
        'Unable to connect. Check your internet connection and try again.',
      'session-expired' ||
      'user-token-expired' ||
      'invalid-user-token' ||
      'requires-recent-login' => sessionExpired,
      'operation-not-allowed' =>
        'Email sign-in is currently unavailable. Contact support for help.',
      'permission-denied' => 'You do not have permission to access this account. Contact support for help.',
      'profile-creation-failed' => 'Your account was created, but setup could not finish. Sign in with your email and password to try again.',
      _ => 'We could not complete your request. Please try again.',
    };
  }
}
