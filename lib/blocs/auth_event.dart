import 'dart:async';

import '../data/auth_repository.dart';
import 'auth_state.dart';
import '../core/constants/auth_messages.dart';

sealed class AuthEvent {}

class SessionChanged extends AuthEvent {
  SessionChanged(this.uid);
  final String? uid;
}

class AuthenticationRequested extends AuthEvent {
  AuthenticationRequested(
    this.action, {
    this.successMessage = AuthMessages.loginSuccess,
  });
  final Future<AdminProfile> Function() action;
  final String successMessage;
  final result = Completer<AuthState>();
}

class LogoutRequested extends AuthEvent {
  LogoutRequested({this.sessionExpired = false});
  final bool sessionExpired;
}

class BiometricLoginRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  PasswordResetRequested(this.email);
  final String email;
}
