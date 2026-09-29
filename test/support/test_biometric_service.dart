import 'dart:async';

import 'package:storeventory/services/biometric_service.dart';

class TestBiometricService extends BiometricService {
  bool available = true;
  bool accepted = true;
  int calls = 0;
  Completer<bool>? gate;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate() async {
    calls++;
    return gate == null ? accepted : await gate!.future;
  }
}
