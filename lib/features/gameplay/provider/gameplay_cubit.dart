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

    // Clear any active hint when the player taps anything.
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

  // Highlights the first active piece whose path is currently clear.
  // Returns true if a hint was found, false if no moves are possible.
  bool requestHint() {
    if (state.phase != GamePhase.playing) return false;

    final free = state.pieces
        .where((p) => p.isActive && state.isPathClear(p))
        .toList();
    if (free.isEmpty) return false;

    final hintId = free.first.id;
    emit(state.copyWith(
      pieces: state.pieces
          .map((p) => p.copyWith(isHinted: p.id == hintId))
          .toList(),
    ));
    return true;
  }

  void clearHint() {
    emit(state.copyWith(pieces: _clearAllHints(state.pieces)));
  }

  List<GamePiece> _clearAllHints(List<GamePiece> pieces) =>
      pieces.map((p) => p.isHinted ? p.copyWith(isHinted: false) : p).toList();

  /// Automatically taps pieces one-by-one in a valid solve order.
  /// Each tap is separated by 700 ms so the exit animation can finish.
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
