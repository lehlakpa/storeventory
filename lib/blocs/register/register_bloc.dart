import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth_bloc.dart';
import '../../core/constants/auth_messages.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc(this.auth) : super(const RegisterState()) {
    on<RegisterRequested>((event, emit) async {
      if (state.busy || auth.state.busy) return;
      emit(const RegisterState(busy: true));
      final result = await auth.authenticate(
        () => auth.repository.register(event.name, event.email, event.password),
        successMessage: AuthMessages.registerSuccess,
      );
      emit(RegisterState(success: result.profile != null, error: result.error));
    });
  }
  final AuthBloc auth;
}
