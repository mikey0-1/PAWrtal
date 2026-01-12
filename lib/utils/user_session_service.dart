import 'package:get_storage/get_storage.dart';

class UserSessionService {
  final _storage = GetStorage();

  String get userId => _storage.read("userId") ?? '';

  // Add these public getters
  String get userName => _storage.read("userName") ?? "Unknown User";
  String get userEmail => _storage.read("email") ?? "";
  String get userRole => _storage.read("role") ?? "user";
  String get userPhone => _storage.read("phone") ?? "";

  // Generic getter for any key
  T? read<T>(String key) => _storage.read(key);

  // Generic setter for any key
  void write(String key, dynamic value) => _storage.write(key, value);

  void saveUserId(String id) => _storage.write('userId', id);

  Future<void> clearSession() async {
    await _storage.erase();
  }

  // Add debugging method
  void debugSession() {}

  // Check if user is logged in
  bool get isLoggedIn => userId.isNotEmpty;

  bool canEditName() {
    final idVerified = read<bool>('idVerified') ?? false;
    return !idVerified;
  }

  // Get all keys
  Iterable<String> getKeys() => _storage.getKeys();

  // Get all values
  Iterable<dynamic> getValues() => _storage.getValues();
}
