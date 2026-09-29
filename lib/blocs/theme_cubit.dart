import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/secure_storage_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light) {
    _load();
  }

  bool _changed = false;
  Future<void> _load() async {
    final mode = await SecureStorageService.storage.read(key: 'theme_mode');
    if (!isClosed && !_changed) {
      emit(mode == 'dark' ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _changed = true;
    await SecureStorageService.storage.write(
      key: 'theme_mode',
      value: mode.name,
    );
    if (!isClosed) emit(mode);
  }
}
