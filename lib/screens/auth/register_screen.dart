import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/register/register_bloc.dart';
import '../../blocs/register/register_event.dart';
import '../../blocs/register/register_state.dart';

import 'auth_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => RegisterBloc(context.read<AuthBloc>()),
    child: BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) => AuthForm(
        register: true,
        busy: state.busy,
        error: state.error,
        onSubmit: (name, email, password) => context.read<RegisterBloc>().add(
          RegisterRequested(name, email, password),
        ),
      ),
    ),
  );
}
