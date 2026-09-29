sealed class LoginEvent {}

class LoginRequested extends LoginEvent {
  LoginRequested(this.email, this.password);
  final String email, password;
}
