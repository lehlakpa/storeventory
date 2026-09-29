import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this.auth) : super(const LoginState()) {
    on<LoginRequested>((event, emit) async {
      if (state.busy || auth.state.busy) return;
      emit(const LoginState(busy: true));
      final result = await auth.authenticate(
        () => auth.repository.login(event.email, event.password),
      );
      emit(LoginState(success: result.profile != null, error: result.error));
    });
  }
  final AuthBloc auth;
}
