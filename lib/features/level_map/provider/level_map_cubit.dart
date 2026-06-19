import 'package:flutter_bloc/flutter_bloc.dart';
import 'level_map_state.dart';

class LevelMapCubit extends Cubit<LevelMapState> {
  LevelMapCubit() : super(LevelMapState.mock());

  void setActiveTab(int index) {
    emit(state.copyWith(activeTab: index));
  }

  /// Dev helper: unlock the next locked level for visual testing.
  void devUnlockNext() {
    final levels = List<LevelData>.from(state.levels);
    final currentIndex = levels.indexWhere((l) => l.status == LevelStatus.current);
    if (currentIndex == -1 || currentIndex + 1 >= levels.length) return;

    levels[currentIndex] = LevelData(
      id: levels[currentIndex].id,
      status: LevelStatus.completed,
      stars: 2,
    );
    levels[currentIndex + 1] = LevelData(
      id: levels[currentIndex + 1].id,
      status: LevelStatus.current,
    );
    emit(state.copyWith(levels: levels));
  }
}
