import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  static const _preferenceKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _disposed = false;
  int _revision = 0;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final revision = _revision;
    final preferences = await SharedPreferences.getInstance();
    if (_disposed || revision != _revision) return;
    final savedMode = preferences.getString(_preferenceKey);
    _themeMode = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_disposed) return;
    _revision++;
    _themeMode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, mode.name);
  }
}
