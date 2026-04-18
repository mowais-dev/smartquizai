import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeBox = 'theme_box';
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_themeBox);
    final themeIndex = box.get(
      _themeKey,
      defaultValue: ThemeMode.dark.index,
    ); // 0 = system, 1 = light, 2 = dark
    emit(ThemeMode.values[themeIndex]);
  }

  Future<void> toggleTheme() async {
    final newThemeMode = state == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    emit(newThemeMode);
    await _saveTheme(newThemeMode);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    emit(themeMode);
    await _saveTheme(themeMode);
  }

  Future<void> _saveTheme(ThemeMode themeMode) async {
    final box = await Hive.openBox(_themeBox);
    await box.put(_themeKey, themeMode.index);
  }
}
