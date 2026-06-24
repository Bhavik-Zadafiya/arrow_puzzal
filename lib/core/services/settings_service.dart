import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight singleton for misc user preferences.
/// Call [init] once at app startup after WidgetsFlutterBinding.ensureInitialized().
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Haptics ────────────────────────────────────────────────────────────────

  bool get hapticsEnabled => _prefs.getBool('haptics_enabled') ?? true;

  Future<void> setHapticsEnabled(bool v) =>
      _prefs.setBool('haptics_enabled', v);

  // ── Difficulty (1–10) ─────────────────────────────────────────────────────
  //
  // 1 = easiest, 5 = default, 10 = intense.
  // Stored as int so it survives restarts.

  int get difficultyLevel => (_prefs.getInt('difficulty_level') ?? 1).clamp(1, 10);

  Future<void> setDifficultyLevel(int v) =>
      _prefs.setInt('difficulty_level', v.clamp(1, 10));
}
