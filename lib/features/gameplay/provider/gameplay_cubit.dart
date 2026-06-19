import 'package:flutter_bloc/flutter_bloc.dart';
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

    if (state.isPathClear(piece)) {
      emit(state.copyWith(
        pieces: state.pieces
            .map((p) => p.id == pieceId ? p.copyWith(isExiting: true) : p)
            .toList(),
      ));
    } else {
      final newMistakes = state.mistakes + 1;
      emit(state.copyWith(
        pieces: state.pieces
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

  // Stub — wire real AdMob rewarded ad when App ID is ready
  void watchAd() =>
      emit(state.copyWith(mistakes: 0, phase: GamePhase.playing));

  // Stub — wire real lifeline deduction from LevelMapCubit / persistence
  void spendLifeline() {
    if (state.mockLifelines <= 0) return;
    emit(state.copyWith(
      mistakes: 0,
      phase: GamePhase.playing,
      mockLifelines: state.mockLifelines - 1,
    ));
  }
}
