sealed class RegisterEvent {}

class RegisterRequested extends RegisterEvent {
  RegisterRequested(this.name, this.email, this.password);
  final String name, email, password;
}
