import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/daily_service.dart';
import '../../../core/services/progress_service.dart';
import 'level_map_state.dart';

class LevelMapCubit extends Cubit<LevelMapState> {
  LevelMapCubit() : super(LevelMapState.fromProgress());

  void setActiveTab(int index) => emit(state.copyWith(activeTab: index));

  /// Reload level list from persisted progress (call after returning from gameplay).
  void reload() =>
      emit(LevelMapState.fromProgress().copyWith(activeTab: state.activeTab));

  /// Claim today's daily reward (+1 lifeline).
  Future<bool> claimDailyReward() async {
    final claimed = await DailyService.instance.claimReward();
    if (claimed) {
      await ProgressService.instance.addLifelines(1);
      reload();
    }
    return claimed;
  }

  /// Dev helper: reset all progress back to level 1.
  Future<void> devResetProgress() async {
    await ProgressService.instance.resetProgress();
    reload();
  }
}
