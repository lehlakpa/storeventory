import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storeventory/core/constants/auth_messages.dart';

void main() {
  test('credential failures share a clear message without backend details', () {
    for (final code in [
      'invalid-credential',
      'wrong-password',
      'user-not-found',
    ]) {
      final message = AuthMessages.error(
        FirebaseException(
          plugin: 'firebase_auth',
          code: code,
          message: 'Internal backend details',
        ),
      );
      expect(
        message,
        'The email or password is incorrect. Check your details and try again.',
      );
      expect(message, isNot(contains('Internal backend details')));
    }
  });
  test('network failures give a connection recovery step', () {
    expect(
      AuthMessages.error(
        FirebaseException(
          plugin: 'firebase_auth',
          code: 'network-request-failed',
        ),
      ),
      contains('Check your internet connection'),
    );
  });
  test('unknown failures never expose raw technical details', () {
    expect(
      AuthMessages.error(
        FirebaseException(
          plugin: 'firebase_auth',
          code: 'new-error',
          message: 'sensitive details',
        ),
      ),
      'We could not complete your request. Please try again.',
    );
  });
}
