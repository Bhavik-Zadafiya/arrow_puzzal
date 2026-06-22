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
    // All 200 levels unlocked for testing — every level is tappable.
    final levels = List.generate(200, (i) {
      final id = i + 1;
      return LevelData(id: id, status: LevelStatus.current);
    });
    return LevelMapState(
      levels: levels,
      lifelineCount: 7,
      lifelineMax: 10,
      regenSecondsRemaining: 840,
    );
  }
}
