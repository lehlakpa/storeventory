import 'dart:async';

import 'package:storeventory/services/biometric_service.dart';

class TestBiometricService extends BiometricService {
  bool enabled = true;
  final Map<String, bool> preferences = {};
  @override
  Future<bool> isEnabled(String uid) async => preferences[uid] ?? enabled;
  @override
  Future<void> setEnabled(String uid, bool value) async {
    preferences[uid] = value;
  }

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
