import '../../../core/services/progress_service.dart';
import '../data/level_definition.dart';

enum GamePhase { playing, failed, levelComplete }

enum HintResult { shown, noMovesAvailable, exhausted }

class GamePiece {
  const GamePiece({
    required this.id,
    required this.cells,
    required this.direction,
    this.isExiting = false,
    this.hasExited = false,
    this.shakeCount = 0,
    this.isHinted = false,
  });

  final String id;
  final List<GridPos> cells;
  final Direction direction;
  final bool isExiting;
  final bool hasExited;
  final int shakeCount;
  final bool isHinted;

  bool get isActive => !isExiting && !hasExited;

  GamePiece copyWith({
    bool? isExiting,
    bool? hasExited,
    int? shakeCount,
    bool? isHinted,
  }) =>
      GamePiece(
        id: id,
        cells: cells,
        direction: direction,
        isExiting: isExiting ?? this.isExiting,
        hasExited: hasExited ?? this.hasExited,
        shakeCount: shakeCount ?? this.shakeCount,
        isHinted: isHinted ?? this.isHinted,
      );
}

class GameplayState {
  const GameplayState({
    required this.level,
    required this.pieces,
    required this.mistakes,
    required this.phase,
    required this.lifelineCount,
    required this.hintsRemaining,
  });

  final LevelDefinition level;
  final List<GamePiece> pieces;
  final int mistakes;
  final GamePhase phase;
  final int lifelineCount;
  final int hintsRemaining;

  static const int maxMistakes = 3;

  static GameplayState fromLevel(LevelDefinition level) => GameplayState(
        level: level,
        pieces: level.pieces
            .map((p) => GamePiece(
                  id: p.id,
                  cells: p.cells,
                  direction: p.direction,
                ))
            .toList(),
        mistakes: 0,
        phase: GamePhase.playing,
        lifelineCount: ProgressService.instance.lifelineCount,
        hintsRemaining: ProgressService.instance.hintsRemainingToday,
      );

  GameplayState copyWith({
    List<GamePiece>? pieces,
    int? mistakes,
    GamePhase? phase,
    int? lifelineCount,
    int? hintsRemaining,
  }) =>
      GameplayState(
        level: level,
        pieces: pieces ?? this.pieces,
        mistakes: mistakes ?? this.mistakes,
        phase: phase ?? this.phase,
        lifelineCount: lifelineCount ?? this.lifelineCount,
        hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      );

  GamePiece? pieceAt(int row, int col, {bool includeExiting = false}) {
    for (final p in pieces) {
      final matches = includeExiting ? !p.hasExited : p.isActive;
      if (matches) {
        for (final cell in p.cells) {
          if (cell.row == row && cell.col == col) return p;
        }
      }
    }
    return null;
  }

  bool isPathClear(GamePiece piece) {
    if (piece.cells.isEmpty) return true;
    final head = piece.cells.last;
    // Pieces that are currently animating out are treated as already gone —
    // they must not block valid taps or waste lifelines.
    switch (piece.direction) {
      case Direction.right:
        for (int c = head.col + 1; c < level.cols; c++) {
          final other = pieceAt(head.row, c);
          if (other != null && other.id != piece.id) return false;
        }
      case Direction.left:
        for (int c = head.col - 1; c >= 0; c--) {
          final other = pieceAt(head.row, c);
          if (other != null && other.id != piece.id) return false;
        }
      case Direction.up:
        for (int r = head.row - 1; r >= 0; r--) {
          final other = pieceAt(r, head.col);
          if (other != null && other.id != piece.id) return false;
        }
      case Direction.down:
        for (int r = head.row + 1; r < level.rows; r++) {
          final other = pieceAt(r, head.col);
          if (other != null && other.id != piece.id) return false;
        }
    }
    return true;
  }
}
