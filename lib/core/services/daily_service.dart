import 'package:shared_preferences/shared_preferences.dart';
import '../../features/gameplay/data/level_definition.dart';
import '../../features/gameplay/data/level_generator.dart';
import '../../features/gameplay/data/shape_masks.dart';
import '../../features/gameplay/data/solvability.dart';

class DayInfo {
  const DayInfo({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.isCompleted,
    required this.stars,
  });
  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool isCompleted;
  final int stars;
}

class DailyService {
  DailyService._();
  static final DailyService instance = DailyService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Date helpers ────────────────────────────────────────────────────────────

  String _key(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  String get _todayKey => _key(DateTime.now());

  // ── Queries ──────────────────────────────────────────────────────────────────

  bool get isCompletedToday => _prefs.getBool('daily_done_$_todayKey') ?? false;
  int get todayStars => _prefs.getInt('daily_stars_$_todayKey') ?? 0;
  int get streak => _prefs.getInt('daily_streak') ?? 0;
  int get bestStreak => _prefs.getInt('daily_best_streak') ?? 0;
  bool get isRewardClaimedToday =>
      _prefs.getBool('daily_reward_$_todayKey') ?? false;

  bool isDayCompleted(DateTime d) =>
      _prefs.getBool('daily_done_${_key(d)}') ?? false;

  int starsForDay(DateTime d) =>
      _prefs.getInt('daily_stars_${_key(d)}') ?? 0;

  /// All days in [year]/[month] with their completion status.
  List<DayInfo> daysInMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    return List.generate(daysInMonth, (i) {
      final date = DateTime(year, month, i + 1);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isFuture = date.isAfter(today);
      final done = isDayCompleted(date);
      return DayInfo(
        date: date,
        isToday: isToday,
        isFuture: isFuture,
        isCompleted: done,
        stars: starsForDay(date),
      );
    });
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  Future<void> completeToday(int stars) async {
    if (isCompletedToday) {
      if (stars > todayStars) {
        await _prefs.setInt('daily_stars_$_todayKey', stars);
      }
      return;
    }
    await _prefs.setBool('daily_done_$_todayKey', true);
    await _prefs.setInt('daily_stars_$_todayKey', stars);

    final yesterday = _key(DateTime.now().subtract(const Duration(days: 1)));
    final hadYesterday = _prefs.getBool('daily_done_$yesterday') ?? false;
    final newStreak = hadYesterday ? streak + 1 : 1;
    await _prefs.setInt('daily_streak', newStreak);
    if (newStreak > bestStreak) {
      await _prefs.setInt('daily_best_streak', newStreak);
    }
  }

  Future<bool> claimReward() async {
    if (!isCompletedToday || isRewardClaimedToday) return false;
    await _prefs.setBool('daily_reward_$_todayKey', true);
    return true;
  }

  // ── Daily puzzle ─────────────────────────────────────────────────────────────

  static const _shapes = ShapeType.values;

  String shapeEmojiFor(DateTime d) {
    const emojis = [
      '❤️', '⭐', '⭕', '◆', '✚', '⬡',
      '➡️', '🌙', '⚡', '🌲', '🐟', '⛵', '🏠', '🔔',
    ];
    return emojis[d.day % emojis.length];
  }

  String get todayShapeEmoji => shapeEmojiFor(DateTime.now());

  LevelDefinition levelFor({DateTime? date}) {
    final d = date ?? DateTime.now();
    final baseSeed = int.parse(_key(d));
    final shape = _shapes[d.day % _shapes.length];
    const rows = 26;
    const cols = 26;
    final mask = buildShapeMask(shape, rows, cols);

    LevelDefinition? best;
    for (int attempt = 0; attempt < 12; attempt++) {
      final seed = (baseSeed + attempt * 999_983) & 0xFFFFFFFF;
      final level = generateLevel(
        id: 'daily_${_key(d)}',
        rows: rows,
        cols: cols,
        seed: seed,
        minTurns: 4,
        maxTurns: 8,
        maxStep: 8,
        complexity: 500,
        shapeMask: mask,
      );
      if (checkSolvability(level).isSolvable) return level;
      best ??= level;
    }
    return best!;
  }

  LevelDefinition get todayLevel => levelFor();

  Duration get timeUntilReset {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }
}
