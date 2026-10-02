import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../core/constants/auth_messages.dart';
import '../data/auth_repository.dart';

Future<bool> confirmSensitiveAction(BuildContext context) async {
  final repository = context.read<AuthBloc>().repository;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PasswordDialog(repository: repository),
      ) ??
      false;
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.repository});
  final AuthRepository repository;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.reauthenticate(_password.text);
      if (!mounted) return;
      _password.clear();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _password.clear();
      setState(() {
        _busy = false;
        _error = AuthMessages.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Verify your password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your account password to confirm this sensitive action.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _error,
                errorMaxLines: 4,
              ),
              onSubmitted: (_) => _verify(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _verify,
          child: Text(_busy ? 'Verifying...' : 'Verify'),
        ),
      ],
    ),
  );
}
