import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDriveEmail = 'drive_email';
const _kSyncEnabled = 'sync_enabled';

class SharedPrefsService {
  final SharedPreferences _prefs;

  SharedPrefsService(this._prefs);

  // ── Google Drive ──────────────────────────────────────────────

  String? get driveEmail => _prefs.getString(_kDriveEmail);

  Future<void> saveDriveEmail(String email) =>
      _prefs.setString(_kDriveEmail, email);

  Future<void> clearDriveEmail() => _prefs.remove(_kDriveEmail);

  // ── Sync ──────────────────────────────────────────────────────

  bool get isSyncEnabled => _prefs.getBool(_kSyncEnabled) ?? false;

  Future<void> setSyncEnabled(bool value) =>
      _prefs.setBool(_kSyncEnabled, value);

  Future<void> clearSyncEnabled() => _prefs.remove(_kSyncEnabled);

  // ── Reader ──────────────────────────────────────────────────────

  bool get isVerticalReadingMode => _prefs.getBool('vertical_reading_mode') ?? true;

  Future<void> setVerticalReadingMode(bool value) =>
      _prefs.setBool('vertical_reading_mode', value);

  // ── Theme ───────────────────────────────────────────────────────

  bool get isDarkMode => _prefs.getBool('is_dark_mode') ?? false;

  Future<void> setDarkMode(bool value) => _prefs.setBool('is_dark_mode', value);
}

final sharedPrefsServiceProvider = Provider<SharedPrefsService>(
  (ref) => throw UnimplementedError('SharedPrefsService not initialized'),
);
