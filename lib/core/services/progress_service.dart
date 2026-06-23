import 'package:shared_preferences/shared_preferences.dart';

/// Persists level progress (stars earned, highest unlocked level) via SharedPreferences.
/// Call [init] once at app startup before using any other methods.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  /// The highest level number that is currently unlocked (default: 1).
  int get highestUnlocked => _prefs.getInt('highest_unlocked') ?? 1;

  /// Stars earned for [level] (0 = not completed, 1–3 = stars).
  int starsFor(int level) => _prefs.getInt('stars_$level') ?? 0;

  // ── Lifelines ──────────────────────────────────────────────────────────────

  int get lifelineCount => _prefs.getInt('lifeline_count') ?? 7;

  Future<void> addLifelines(int n) async {
    await _prefs.setInt('lifeline_count', lifelineCount + n);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Record completion of [level] with [stars].
  /// Only upgrades stars if better. Advances [highestUnlocked] if at the frontier.
  Future<void> completeLevel(int level, int stars) async {
    final best = starsFor(level);
    if (stars > best) {
      await _prefs.setInt('stars_$level', stars);
    }
    if (level >= highestUnlocked && level < 500) {
      await _prefs.setInt('highest_unlocked', level + 1);
    }
  }

  /// Dev helper: wipe all progress back to the beginning.
  Future<void> resetProgress() async {
    await _prefs.setInt('highest_unlocked', 1);
    await _prefs.setInt('lifeline_count', 7);
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith('stars_') || k.startsWith('daily_'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
