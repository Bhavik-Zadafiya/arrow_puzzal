import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight singleton for misc user preferences (haptics, etc.).
/// Call [init] once at app startup after WidgetsFlutterBinding.ensureInitialized().
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get hapticsEnabled => _prefs.getBool('haptics_enabled') ?? true;

  Future<void> setHapticsEnabled(bool v) =>
      _prefs.setBool('haptics_enabled', v);
}
