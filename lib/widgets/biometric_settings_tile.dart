import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../core/constants/auth_messages.dart';

class BiometricSettingsTile extends StatefulWidget {
  const BiometricSettingsTile({super.key, required this.uid});
  final String uid;

  @override
  State<BiometricSettingsTile> createState() => _BiometricSettingsTileState();
}

class _BiometricSettingsTileState extends State<BiometricSettingsTile> {
  bool _enabled = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await context.read<AuthBloc>().biometrics.isEnabled(
        widget.uid,
      );
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _busy = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load fingerprint settings. Tap to retry.';
          _busy = false;
        });
      }
    }
  }

  Future<void> _change(bool enabled) async {
    if (_busy) return;
    final auth = context.read<AuthBloc>();
    final uid = widget.uid;
    if (auth.state.busy || auth.state.profile?.uid != uid) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (enabled) {
        if (!await auth.biometrics.isAvailable()) {
          _notify(
            'No biometrics are available. Set up fingerprint or face recognition in your device settings first.',
          );
          return;
        }
        if (!await auth.biometrics.authenticate()) {
          _notify(
            'Verification was cancelled or failed. Fingerprint login remains disabled.',
          );
          return;
        }
      }
      if (!mounted || auth.state.profile?.uid != uid || auth.state.busy) return;
      await auth.biometrics.setEnabled(uid, enabled);
      if (!mounted) return;
      setState(() => _enabled = enabled);
      _notify(
        enabled
            ? 'Fingerprint login enabled.'
            : 'Fingerprint login disabled. Use your password to sign in.',
      );
    } catch (e) {
      _notify(AuthMessages.error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    secondary: _busy
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.fingerprint),
    title: const Text('Fingerprint login'),
    subtitle: Text(
      _error ??
          (_enabled
              ? 'Unlock with fingerprint or face recognition for up to 30 days after password sign-in.'
              : 'Verify your fingerprint or face to enable biometric login.'),
    ),
    value: _enabled,
    onChanged: _busy
        ? null
        : (value) {
            if (_error != null) {
              setState(() => _busy = true);
              _load();
            } else {
              _change(value);
            }
          },
  );
}
