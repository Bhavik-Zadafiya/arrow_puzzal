import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/progress_service.dart';
import '../data/level_definition.dart';
import 'gameplay_state.dart';

class GameplayCubit extends Cubit<GameplayState> {
  GameplayCubit(LevelDefinition level) : super(GameplayState.fromLevel(level));

  void tapPiece(String pieceId) {
    if (state.phase != GamePhase.playing) return;

    final piece = state.pieces.firstWhere(
      (p) => p.id == pieceId,
      orElse: () => throw StateError('Unknown piece: $pieceId'),
    );
    if (!piece.isActive) return;

    final cleared = _clearAllHints(state.pieces);

    if (state.isPathClear(piece)) {
      emit(state.copyWith(
        pieces: cleared
            .map((p) => p.id == pieceId ? p.copyWith(isExiting: true) : p)
            .toList(),
      ));
    } else {
      final newMistakes = state.mistakes + 1;
      emit(state.copyWith(
        pieces: cleared
            .map((p) =>
                p.id == pieceId ? p.copyWith(shakeCount: p.shakeCount + 1) : p)
            .toList(),
        mistakes: newMistakes,
        phase: newMistakes >= GameplayState.maxMistakes
            ? GamePhase.failed
            : state.phase,
      ));
    }
  }

  void pieceExited(String pieceId) {
    if (isClosed) return;
    final updated = state.pieces
        .map((p) =>
            p.id == pieceId ? p.copyWith(hasExited: true, isExiting: false) : p)
        .toList();

    emit(state.copyWith(
      pieces: updated,
      phase: updated.every((p) => p.hasExited)
          ? GamePhase.levelComplete
          : state.phase,
    ));
  }

  Future<HintResult> requestHint() async {
    if (state.phase != GamePhase.playing) return HintResult.noMovesAvailable;

    // Check daily quota first — before spending anything.
    if (ProgressService.instance.hintsRemainingToday <= 0) {
      return HintResult.exhausted;
    }

    final free = state.pieces
        .where((p) => p.isActive && state.isPathClear(p))
        .toList();
    if (free.isEmpty) return HintResult.noMovesAvailable;

    await ProgressService.instance.useHint();

    final hintId = free.first.id;
    emit(state.copyWith(
      pieces: state.pieces
          .map((p) => p.copyWith(isHinted: p.id == hintId))
          .toList(),
      hintsRemaining: ProgressService.instance.hintsRemainingToday,
    ));
    return HintResult.shown;
  }

  void clearHint() {
    emit(state.copyWith(pieces: _clearAllHints(state.pieces)));
  }

  /// Ad reward: grant 3 extra hints for today.
  Future<void> watchHintAd() async {
    await ProgressService.instance.addHints(3);
    emit(state.copyWith(
      hintsRemaining: ProgressService.instance.hintsRemainingToday,
    ));
  }

  List<GamePiece> _clearAllHints(List<GamePiece> pieces) =>
      pieces.map((p) => p.isHinted ? p.copyWith(isHinted: false) : p).toList();

  // ── Continue dialog actions ────────────────────────────────────────────────

  /// Rewarded ad: reset mistakes, grant 1 lifeline as ad reward.
  Future<void> watchAd() async {
    await ProgressService.instance.addLifelines(1);
    emit(state.copyWith(
      mistakes: 0,
      phase: GamePhase.playing,
      lifelineCount: ProgressService.instance.lifelineCount,
    ));
  }

  /// Spend one real lifeline to continue.
  Future<void> spendLifeline() async {
    final spent = await ProgressService.instance.spendLifeline();
    if (!spent) return; // no lifelines left — shouldn't happen if UI is correct
    emit(state.copyWith(
      mistakes: 0,
      phase: GamePhase.playing,
      lifelineCount: ProgressService.instance.lifelineCount,
    ));
  }

  // ── Dev / auto-solve ──────────────────────────────────────────────────────

  Future<void> autoSolve() async {
    while (!isClosed && state.phase == GamePhase.playing) {
      final free = state.pieces
          .where((p) => p.isActive && state.isPathClear(p))
          .toList();
      if (free.isEmpty) break;
      tapPiece(free.first.id);
      await Future.delayed(const Duration(milliseconds: 700));
    }
  }
}
