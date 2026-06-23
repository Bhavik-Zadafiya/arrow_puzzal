import '../../../core/services/progress_service.dart';

enum LevelStatus { locked, current, completed }

class LevelData {
  const LevelData({
    required this.id,
    required this.status,
    this.stars = 0,
  });

  final int id;
  final LevelStatus status;

  /// 0 = not completed yet, 1–3 = stars earned.
  final int stars;

  bool get isMilestone => id % 10 == 0;
}

class LevelMapState {
  const LevelMapState({
    required this.levels,
    required this.lifelineCount,
    required this.lifelineMax,
    this.regenSecondsRemaining = 0,
    this.activeTab = 0,
  });

  final List<LevelData> levels;
  final int lifelineCount;
  final int lifelineMax;
  final int regenSecondsRemaining;
  final int activeTab;

  LevelMapState copyWith({
    List<LevelData>? levels,
    int? lifelineCount,
    int? lifelineMax,
    int? regenSecondsRemaining,
    int? activeTab,
  }) =>
      LevelMapState(
        levels: levels ?? this.levels,
        lifelineCount: lifelineCount ?? this.lifelineCount,
        lifelineMax: lifelineMax ?? this.lifelineMax,
        regenSecondsRemaining:
            regenSecondsRemaining ?? this.regenSecondsRemaining,
        activeTab: activeTab ?? this.activeTab,
      );

  /// Build state from persisted progress. ProgressService must be initialised.
  static LevelMapState fromProgress() {
    final svc = ProgressService.instance;
    final highest = svc.highestUnlocked;

    final levels = List.generate(500, (i) {
      final id = i + 1;
      final stars = svc.starsFor(id);
      LevelStatus status;
      if (id > highest) {
        status = LevelStatus.locked;
      } else if (stars > 0) {
        status = LevelStatus.completed;
      } else {
        // Unlocked but not beaten — treat as current (playable frontier).
        status = LevelStatus.current;
      }
      return LevelData(id: id, status: status, stars: stars);
    });

    return LevelMapState(
      levels: levels,
      lifelineCount: svc.lifelineCount.clamp(0, 10),
      lifelineMax: 10,
      regenSecondsRemaining: 840,
    );
  }
}
