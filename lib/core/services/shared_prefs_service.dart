import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDriveEmail = 'drive_email';

class SharedPrefsService {
  final SharedPreferences _prefs;

  SharedPrefsService(this._prefs);

  String? get driveEmail => _prefs.getString(_kDriveEmail);

  Future<void> saveDriveEmail(String email) =>
      _prefs.setString(_kDriveEmail, email);

  Future<void> clearDriveEmail() => _prefs.remove(_kDriveEmail);
}

final sharedPrefsServiceProvider = Provider<SharedPrefsService>(
  (ref) => throw UnimplementedError('SharedPrefsService not initialized'),
);
