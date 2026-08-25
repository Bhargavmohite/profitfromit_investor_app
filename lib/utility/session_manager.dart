import 'package:profit_from_it_investors/utility/local_storage.dart';

class SessionManager {
  static String? _selectedUserId;

  /// Called when app starts
  static Future<void> initialize() async {
    _selectedUserId = await LocalStorage.getId();
  }

  static String get userId => _selectedUserId ?? "";

  static void changeUser(String id) {
    _selectedUserId = id;
  }

  static Future<void> resetToLoggedInUser() async {
    _selectedUserId = await LocalStorage.getId();
  }
}