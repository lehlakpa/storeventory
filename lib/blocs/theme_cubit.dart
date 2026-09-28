import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light) {
    _load();
  }

  bool _changed = false;
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!isClosed && !_changed) {
      emit(
        prefs.getString('theme_mode') == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light,
      );
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _changed = true;
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString('theme_mode', mode.name);
    if (!saved) throw StateError('Unable to save appearance preference.');
    if (!isClosed) emit(mode);
  }
}
