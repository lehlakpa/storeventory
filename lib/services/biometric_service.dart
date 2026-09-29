import 'package:local_auth/local_auth.dart';

import 'secure_storage_service.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isEnabled(String uid) async =>
      await SecureStorageService.storage.read(key: 'biometric_enabled_$uid') ==
      'true';

  Future<void> setEnabled(String uid, bool enabled) => SecureStorageService
      .storage
      .write(key: 'biometric_enabled_$uid', value: enabled.toString());

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock your Storeventory account',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
