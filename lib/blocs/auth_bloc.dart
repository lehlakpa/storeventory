import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

sealed class AuthEvent {}

class SessionChanged extends AuthEvent {
  SessionChanged(this.uid);
  final String? uid;
}

class LoginRequested extends AuthEvent {
  LoginRequested(this.email, this.password);
  final String email, password;
}

class RegisterRequested extends AuthEvent {
  RegisterRequested(this.name, this.email, this.password);
  final String name, email, password;
}

class LogoutRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  PasswordResetRequested(this.email);
  final String email;
}

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

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repository) : super(const AuthState(initializing: true)) {
    on<SessionChanged>((event, emit) async {
      if (state.busy ||
          (event.uid != null && state.profile?.uid == event.uid)) {
        return;
      }
      final revision = ++_revision;
      if (event.uid == null) {
        emit(const AuthState());
        return;
      }
      emit(const AuthState(initializing: true));
      try {
        final profile = await repository.profile(event.uid!);
        if (revision == _revision) emit(AuthState(profile: profile));
      } catch (e) {
        if (revision == _revision) emit(AuthState(error: _message(e)));
      }
    });
    on<LoginRequested>(
      (event, emit) =>
          _perform(emit, () => repository.login(event.email, event.password)),
    );
    on<RegisterRequested>(
      (event, emit) => _perform(
        emit,
        () => repository.register(event.name, event.email, event.password),
      ),
    );
    on<LogoutRequested>((event, emit) async {
      if (state.busy) return;
      ++_revision;
      final previous = state.profile;
      emit(AuthState(profile: previous, busy: true));
      try {
        await repository.logout();
        emit(const AuthState());
      } catch (e) {
        emit(AuthState(profile: previous, error: _message(e)));
      }
    });
    on<PasswordResetRequested>((event, emit) async {
      if (state.busy) return;
      emit(const AuthState(busy: true));
      try {
        await repository.resetPassword(event.email);
        emit(
          const AuthState(
            message: 'Password reset requested. Check your email.',
          ),
        );
      } catch (e) {
        emit(AuthState(error: _message(e)));
      }
    });
    _subscription = repository.sessions.listen(
      (uid) => add(SessionChanged(uid)),
      onError: (Object _) => add(SessionChanged(null)),
    );
  }
  final AuthRepository repository;
  late final StreamSubscription<String?> _subscription;
  int _revision = 0;
  Future<void> _perform(
    Emitter<AuthState> emit,
    Future<AdminProfile> Function() action,
  ) async {
    if (state.busy) return;
    ++_revision;
    emit(const AuthState(busy: true));
    try {
      emit(AuthState(profile: await action()));
    } catch (e) {
      emit(AuthState(error: _message(e)));
    }
  }

  String _message(Object e) => e is FirebaseException
      ? (e.message ?? 'Authentication failed. Please try again.')
      : 'Unable to access your account. Check your connection and try again.';
  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
