class LoginState {
  const LoginState({this.busy = false, this.success = false, this.error});
  final bool busy, success;
  final String? error;
}
