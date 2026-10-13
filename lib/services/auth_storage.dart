import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  static const String _rememberKey =
      'remember_login';

  static const String _identifierKey =
      'remembered_identifier';

  static const String _passwordKey =
      'remembered_password';

  static const String _currentPasswordKey =
    'current_session_password';   

   Future<void> saveCurrentPassword(
  String password,
) async {
  await _secureStorage.write(
    key: _currentPasswordKey,
    value: password,
  );
}

Future<String?> getCurrentPassword() async {
  return _secureStorage.read(
    key: _currentPasswordKey,
  );
}

Future<void> clearCurrentPassword() async {
  await _secureStorage.delete(
    key: _currentPasswordKey,
  );
}

  Future<void> saveLoginInfo({
    required String identifier,
    required String password,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _rememberKey,
      true,
    );

    await prefs.setString(
      _identifierKey,
      identifier,
    );

    await _secureStorage.write(
      key: _passwordKey,
      value: password,
    );
  }

  Future<void> clearLoginInfo() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_rememberKey);
    await prefs.remove(_identifierKey);

    await _secureStorage.delete(
      key: _passwordKey,
    );
  }

  Future<bool> isRemembered() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _rememberKey,
        ) ??
        false;
  }

  Future<String?> getSavedIdentifier() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _identifierKey,
    );
  }

  Future<String?> getSavedPassword() async {
    return _secureStorage.read(
      key: _passwordKey,
    );
  }
  Future<void> updateSavedPassword(
  String newPassword,
) async {
  final remembered =
      await isRemembered();

  if (!remembered) {
    return;
  }

  await _secureStorage.write(
    key: _passwordKey,
    value: newPassword,
  );
}

Future<void> updateSavedIdentifier(
  String identifier,
) async {
  final remembered =
      await isRemembered();

  if (!remembered) {
    return;
  }

  final prefs =
      await SharedPreferences.getInstance();

  await prefs.setString(
    _identifierKey,
    identifier,
  );
}

}