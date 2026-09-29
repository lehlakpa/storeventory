class RegisterState {
  const RegisterState({this.busy = false, this.success = false, this.error});
  final bool busy, success;
  final String? error;
}
