import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../services/biometric_service.dart';
import '../core/constants/auth_messages.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repository, {BiometricService? biometrics})
    : biometrics = biometrics ?? BiometricService(),
      super(const AuthState(initializing: true)) {
    on<SessionChanged>((event, emit) async {
      final previousUid = _sessionUid;
      if (_sessionUid != event.uid) ++_revision;
      _sessionUid = event.uid;
      if (event.uid == null) {
        _expiryTimer?.cancel();
        ++_revision;
        if (!state.busy &&
            (previousUid != null ||
                state.initializing ||
                state.profile != null)) {
          emit(const AuthState());
        }
        return;
      }
      if (state.busy || state.profile?.uid == event.uid) {
        return;
      }
      ++_revision;
      // A restored Firebase session must be unlocked before exposing its data.
      emit(const AuthState());
    });
    on<BiometricLoginRequested>((event, emit) async {
      if (state.busy || state.profile != null) return;
      final uid = _sessionUid;
      if (uid == null) {
        emit(
          const AuthState(
            error: 'Sign in with your email and password first. Biometrics can unlock your saved session next time.',
          ),
        );
        return;
      }
      final revision = ++_revision;
      emit(const AuthState(busy: true));
      try {
        if (!await this.biometrics.isEnabled(uid)) {
          emit(
            const AuthState(
              error: 'Fingerprint login is disabled. Sign in with your password, then enable it in Settings.',
            ),
          );
          return;
        }
        if (!await this.biometrics.isAvailable()) {
          emit(
            const AuthState(
              error: 'Biometrics are unavailable. Set up fingerprint or face recognition in device settings, or use your password.',
            ),
          );
          return;
        }
        if (!await this.biometrics.authenticate()) {
          emit(
            const AuthState(
              error: 'Biometric verification was cancelled or failed. Try again or use your password.',
            ),
          );
          return;
        }
        if (revision != _revision || uid != _sessionUid) {
          emit(const AuthState(error: 'Your session changed. Sign in again.'));
          return;
        }
        final profile = await repository.unlockSession(uid);
        if (revision == _revision) {
          _scheduleExpiry();
          emit(
            AuthState(profile: profile, message: AuthMessages.biometricSuccess),
          );
        } else {
          emit(const AuthState(error: 'Your session changed. Sign in again.'));
        }
      } catch (e) {
        emit(AuthState(error: AuthMessages.error(e)));
      }
    });
    on<AuthenticationRequested>((event, emit) async {
      await _perform(emit, event.action, event.successMessage);
      event.result.complete(state);
    });
    on<LogoutRequested>((event, emit) async {
      if (state.busy) return;
      ++_revision;
      final previous = state.profile;
      emit(AuthState(profile: previous, busy: true));
      try {
        await repository.logout();
        _sessionUid = null;
        emit(
          AuthState(
            message: event.sessionExpired
                ? AuthMessages.sessionExpired
                : 'You have been signed out.',
          ),
        );
      } catch (e) {
        // Keep account data hidden even if secure-storage cleanup fails.
        emit(AuthState(error: AuthMessages.error(e)));
      }
    });
    on<PasswordResetRequested>((event, emit) async {
      if (state.busy) return;
      emit(const AuthState(busy: true));
      try {
        await repository.resetPassword(event.email);
        emit(
          const AuthState(
            message: 'If an account uses this email, you will receive a password reset link. Check your inbox and spam folder.',
          ),
        );
      } catch (e) {
        emit(AuthState(error: AuthMessages.error(e)));
      }
    });
    _subscription = repository.sessions.listen(
      (uid) => add(SessionChanged(uid)),
      onError: (Object _) => add(SessionChanged(null)),
    );
  }
  final AuthRepository repository;
  final BiometricService biometrics;
  String? _sessionUid;
  late final StreamSubscription<String?> _subscription;
  int _revision = 0;
  Timer? _expiryTimer;

  Future<AuthState> authenticate(
    Future<AdminProfile> Function() action, {
    String successMessage = AuthMessages.loginSuccess,
  }) {
    final event = AuthenticationRequested(
      action,
      successMessage: successMessage,
    );
    add(event);
    return event.result.future;
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expires = repository.sessionExpiresAt;
    if (expires != null) {
      _expiryTimer = Timer(expires.difference(DateTime.now().toUtc()), () {
        if (!isClosed) add(LogoutRequested(sessionExpired: true));
      });
    }
  }

  Future<void> _perform(
    Emitter<AuthState> emit,
    Future<AdminProfile> Function() action,
    String successMessage,
  ) async {
    if (state.busy) return;
    ++_revision;
    emit(const AuthState(busy: true));
    try {
      final profile = await action();
      _scheduleExpiry();
      emit(AuthState(profile: profile, message: successMessage));
    } catch (e) {
      emit(AuthState(error: AuthMessages.error(e)));
    }
  }

  @override
  Future<void> close() async {
    _expiryTimer?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
