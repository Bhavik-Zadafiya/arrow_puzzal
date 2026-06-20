import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_pussal/features/gameplay/data/level_1.dart';
import 'package:arrow_pussal/features/gameplay/provider/gameplay_state.dart';

void main() {
  test('Level 1 is 100% solvable without deadlocks', () {
    var state = GameplayState.fromLevel(kLevel1);

    int steps = 0;
    const maxSteps = 100; // safety limit to prevent infinite loops

    while (state.pieces.any((p) => p.isActive) && steps < maxSteps) {
      bool moved = false;
      for (final piece in state.pieces) {
        if (piece.isActive && state.isPathClear(piece)) {
          // Simulate tap and immediate exit
          final updatedPieces = state.pieces.map((p) {
            if (p.id == piece.id) {
              return p.copyWith(hasExited: true, isExiting: false);
            }
            return p;
          }).toList();
          state = state.copyWith(pieces: updatedPieces);
          moved = true;
          steps++;
          break; // break loop to start check from first piece again with updated state
        }
      }
      if (!moved) {
        // No piece could move, but some are still active - deadlock!
        break;
      }
    }

    final activePieces = state.pieces.where((p) => p.isActive).map((p) => p.id).toList();
    expect(
      activePieces,
      isEmpty,
      reason: 'The level has a deadlock! Remaining active pieces: $activePieces',
    );
    expect(state.phase, GamePhase.playing); // phase remains playing since we manually updated pieces
    debugPrint('Level 1 solved successfully in $steps steps!');
  });
}
