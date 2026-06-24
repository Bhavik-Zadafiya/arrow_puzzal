import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/daily_service.dart';
import '../../../core/services/progress_service.dart';
import 'level_map_state.dart';

class LevelMapCubit extends Cubit<LevelMapState> {
  LevelMapCubit() : super(LevelMapState.fromProgress()) {
    _startRegenTimer();
  }

  Timer? _regenTimer;

  // Tick every second to keep the regen countdown live.
  void _startRegenTimer() {
    _tick(); // immediate first tick
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    final secsRemaining = await ProgressService.instance.processRegen();
    if (isClosed) return;
    emit(state.copyWith(
      lifelineCount: ProgressService.instance.lifelineCount.clamp(0, 10),
      regenSecondsRemaining: secsRemaining,
    ));
  }

  void setActiveTab(int index) => emit(state.copyWith(activeTab: index));

  /// Reload level list + lifeline count from persisted progress.
  void reload() {
    final fresh = LevelMapState.fromProgress();
    emit(fresh.copyWith(activeTab: state.activeTab));
  }

  /// Claim today's daily reward (+1 lifeline).
  Future<bool> claimDailyReward() async {
    final claimed = await DailyService.instance.claimReward();
    if (claimed) {
      await ProgressService.instance.addLifelines(1);
      reload();
    }
    return claimed;
  }

  @override
  Future<void> close() {
    _regenTimer?.cancel();
    return super.close();
  }
}
