import 'package:shared_preferences/shared_preferences.dart';

/// Persists level progress and lifelines via SharedPreferences.
/// Call [init] once at app startup before using any other methods.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  late SharedPreferences _prefs;

  static const int maxLifelines         = 10;
  static const int regenIntervalSeconds = 1800; // 30 min per lifeline

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Level progress ─────────────────────────────────────────────────────────

  int get highestUnlocked => _prefs.getInt('highest_unlocked') ?? 1;

  int starsFor(int level) => _prefs.getInt('stars_$level') ?? 0;

  Future<void> completeLevel(int level, int stars) async {
    final best = starsFor(level);
    if (stars > best) await _prefs.setInt('stars_$level', stars);
    if (level >= highestUnlocked && level < 500) {
      await _prefs.setInt('highest_unlocked', level + 1);
    }
  }

  // ── Lifelines ──────────────────────────────────────────────────────────────

  int get lifelineCount =>
      (_prefs.getInt('lifeline_count') ?? 5).clamp(0, maxLifelines);

  int get _lastRegenEpoch => _prefs.getInt('last_regen_epoch') ?? 0;

  /// Spend one lifeline. Returns false if none available.
  Future<bool> spendLifeline() async {
    final current = lifelineCount;
    if (current <= 0) return false;

    final wasAtMax = current >= maxLifelines;
    await _prefs.setInt('lifeline_count', current - 1);

    // Start the regen clock when dropping below max for the first time.
    if (wasAtMax || _lastRegenEpoch == 0) {
      await _prefs.setInt(
          'last_regen_epoch', DateTime.now().millisecondsSinceEpoch);
    }
    return true;
  }

  /// Grant [n] lifelines (e.g. from ad reward or daily bonus).
  Future<void> addLifelines(int n) async {
    final newCount = (lifelineCount + n).clamp(0, maxLifelines);
    await _prefs.setInt('lifeline_count', newCount);
    // If now at max, stop the regen clock.
    if (newCount >= maxLifelines) await _prefs.remove('last_regen_epoch');
  }

  /// Process any lifelines that have regenerated since last call.
  /// Returns seconds remaining until the NEXT lifeline regenerates (0 = full).
  /// Call this on app start and once per second while the level-map is visible.
  Future<int> processRegen() async {
    final current = lifelineCount;
    if (current >= maxLifelines) {
      await _prefs.remove('last_regen_epoch');
      return 0;
    }

    final now    = DateTime.now().millisecondsSinceEpoch;
    int lastEpoch = _lastRegenEpoch;

    // If clock was never started (e.g. after reset), start it now.
    if (lastEpoch == 0) {
      lastEpoch = now;
      await _prefs.setInt('last_regen_epoch', lastEpoch);
    }

    final elapsedSec = (now - lastEpoch) ~/ 1000;
    final gained     = elapsedSec ~/ regenIntervalSeconds;

    if (gained > 0) {
      final newCount = (current + gained).clamp(0, maxLifelines);
      await _prefs.setInt('lifeline_count', newCount);

      if (newCount >= maxLifelines) {
        await _prefs.remove('last_regen_epoch');
        return 0;
      }

      // Advance the epoch by exactly the consumed intervals.
      final newEpoch = lastEpoch + gained * regenIntervalSeconds * 1000;
      await _prefs.setInt('last_regen_epoch', newEpoch);
      lastEpoch = newEpoch;
    }

    // Seconds until the next regen tick.
    final nextMs = lastEpoch + regenIntervalSeconds * 1000;
    return ((nextMs - now) / 1000).ceil().clamp(0, regenIntervalSeconds);
  }

  // ── Hints ─────────────────────────────────────────────────────────────────

  static const int _dailyHints = 3; // free hints per day

  String get _todayKey {
    final d = DateTime.now();
    return 'hint_date_${d.year}_${d.month}_${d.day}';
  }

  int get hintsRemainingToday {
    final stored = _prefs.getInt(_todayKey);
    if (stored == null) return _dailyHints; // new day → full quota
    return stored.clamp(0, 99);
  }

  /// Consume one hint. Returns false if quota exhausted.
  Future<bool> useHint() async {
    final remaining = hintsRemainingToday;
    if (remaining <= 0) return false;
    await _prefs.setInt(_todayKey, remaining - 1);
    return true;
  }

  /// Grant [n] extra hints (e.g. ad reward). Adds to today's remaining.
  Future<void> addHints(int n) async {
    await _prefs.setInt(_todayKey, hintsRemainingToday + n);
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> resetProgress() async {
    await _prefs.setInt('highest_unlocked', 1);
    await _prefs.setInt('lifeline_count', 5);
    await _prefs.remove('last_regen_epoch');
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith('stars_') || k.startsWith('daily_'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
