enum LevelStatus { locked, current, completed }

class LevelData {
  const LevelData({
    required this.id,
    required this.status,
    this.stars = 0,
  });

  final int id;
  final LevelStatus status;

  /// 0 = not completed, 1–3 = stars earned
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
  }) {
    return LevelMapState(
      levels: levels ?? this.levels,
      lifelineCount: lifelineCount ?? this.lifelineCount,
      lifelineMax: lifelineMax ?? this.lifelineMax,
      regenSecondsRemaining: regenSecondsRemaining ?? this.regenSecondsRemaining,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  static LevelMapState mock() {
    final levels = List.generate(40, (i) {
      final id = i + 1;
      LevelStatus status;
      int stars = 0;
      if (id < 8) {
        status = LevelStatus.completed;
        stars = [3, 2, 3, 1, 3, 2, 3][i % 7];
      } else if (id == 8) {
        status = LevelStatus.current;
      } else {
        status = LevelStatus.locked;
      }
      return LevelData(id: id, status: status, stars: stars);
    });
    return LevelMapState(
      levels: levels,
      lifelineCount: 7,
      lifelineMax: 10,
      regenSecondsRemaining: 840,
    );
  }
}
