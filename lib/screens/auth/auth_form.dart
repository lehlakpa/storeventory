import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/constants/app_assets.dart';
import '../../widgets/custom_loading.dart';
import '../../widgets/auth_feedback.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    this.register = false,
    required this.onSubmit,
    this.busy = false,
    this.error,
    this.message,
    this.onBiometric,
  });
  final void Function(String name, String email, String password) onSubmit;
  final bool busy;
  final String? error, message;
  final VoidCallback? onBiometric;
  final bool register;
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _hide = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.busy || !_form.currentState!.validate()) {
      return;
    }
    widget.onSubmit(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.busy,
    child: Scaffold(
      appBar: widget.register
          ? AppBar(title: const Text('Create Account'))
          : null,
      body: SafeArea(
        child: widget.busy
            ? CustomLoading(
                message: widget.register
                    ? 'Creating your account…'
                    : 'Signing you in…',
              )
            : Center(
                child: SingleChildScrollView(
                  padding: AppSizes.screenPadding,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset(
                            AppAssets.onboardingGrowth,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            widget.register
                                ? 'Create your account'
                                : 'Welcome back',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          if (widget.register) ...[
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter your name'
                                  : null,
                            ),
                            const SizedBox(height: AppSizes.md),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) =>
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v?.trim() ?? '')
                                ? null
                                : 'Enter a valid email address',
                          ),
                          const SizedBox(height: AppSizes.md),
                          TextFormField(
                            controller: _password,
                            obscureText: _hide,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _hide = !_hide),
                                icon: Icon(
                                  _hide
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your password';
                              }
                              if (widget.register && v.length < 6) {
                                return 'Use at least 6 characters for your password';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (widget.register) ...[
                            const SizedBox(height: AppSizes.md),
                            TextFormField(
                              obscureText: _hide,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                              ),
                              validator: (v) => v == _password.text ? null : 'Passwords do not match. Enter the same password again.',
                            ),
                          ],
                          if (widget.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSizes.md),
                              child: AuthFeedback(
                                message: widget.error!,
                                isError: true,
                              ),
                            ),
                          if (widget.message != null)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSizes.md),
                              child: AuthFeedback(message: widget.message!),
                            ),
                          const SizedBox(height: AppSizes.lg),
                          ElevatedButton(
                            onPressed: _submit,
                            child: Text(widget.register ? 'Sign Up' : 'Login'),
                          ),
                          if (!widget.register) ...[
                            const SizedBox(height: AppSizes.md),
                            OutlinedButton.icon(
                              onPressed: widget.onBiometric,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Login with biometrics'),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            const Text(
                              'Use fingerprint  recognition to unlock',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
}
