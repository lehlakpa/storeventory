import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/auth_event.dart';
import '../../blocs/auth_state.dart';
import '../../blocs/login/login_bloc.dart';
import '../../blocs/login/login_event.dart';
import '../../blocs/login/login_state.dart';
import 'auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoginBloc(context.read<AuthBloc>()),
    child: BlocBuilder<LoginBloc, LoginState>(
      builder: (context, login) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, auth) => AuthForm(
          busy: login.busy || auth.busy,
          error: auth.error,
          message: auth.message,
          onSubmit: (_, email, password) =>
              context.read<LoginBloc>().add(LoginRequested(email, password)),
          onBiometric: () =>
              context.read<AuthBloc>().add(BiometricLoginRequested()),
        ),
      ),
    ),
  );
}
