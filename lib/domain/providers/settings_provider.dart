import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyWsUrl = 'ws_url';
  static const String _keyTheme = 'theme_mode';
  static const String _keyDataRetentionDays = 'data_retention_days';
  static const String _keyAutoConnect = 'auto_connect';
  static const String _keyNotifications = 'notifications';

  String _wsUrl = 'wss://echo.websocket.org';
  ThemeMode _themeMode = ThemeMode.dark;
  int _dataRetentionDays = 365;
  bool _autoConnect = true;
  bool _notificationsEnabled = true;

  String get wsUrl => _wsUrl;
  ThemeMode get themeMode => _themeMode;
  int get dataRetentionDays => _dataRetentionDays;
  bool get autoConnect => _autoConnect;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _wsUrl = prefs.getString(_keyWsUrl) ?? _wsUrl;
    _dataRetentionDays = prefs.getInt(_keyDataRetentionDays) ?? _dataRetentionDays;
    _autoConnect = prefs.getBool(_keyAutoConnect) ?? _autoConnect;
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? _notificationsEnabled;
    final themeIndex = prefs.getInt(_keyTheme) ?? ThemeMode.dark.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setWsUrl(String url) async {
    _wsUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWsUrl, url);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
    notifyListeners();
  }

  Future<void> setDataRetentionDays(int days) async {
    _dataRetentionDays = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDataRetentionDays, days);
    notifyListeners();
  }

  Future<void> setAutoConnect(bool value) async {
    _autoConnect = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoConnect, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
    notifyListeners();
  }
}
