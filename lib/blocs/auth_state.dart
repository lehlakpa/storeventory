import '../data/auth_repository.dart';

class AuthState {
  const AuthState({
    this.profile,
    this.initializing = false,
    this.busy = false,
    this.error,
    this.message,
  });
  final AdminProfile? profile;
  final bool initializing, busy;
  final String? error, message;
}
