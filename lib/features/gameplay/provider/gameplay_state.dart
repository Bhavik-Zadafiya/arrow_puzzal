import '../data/level_definition.dart';

enum GamePhase { playing, failed, levelComplete }

class GamePiece {
  const GamePiece({
    required this.id,
    required this.cells,
    required this.direction,
    this.isExiting = false,
    this.hasExited = false,
    this.shakeCount = 0,
  });

  final String id;
  final List<GridPos> cells;
  final Direction direction;
  final bool isExiting;
  final bool hasExited;
  final int shakeCount; // incremented each time a blocked-move is made on this piece

  bool get isActive => !isExiting && !hasExited;

  GamePiece copyWith({
    bool? isExiting,
    bool? hasExited,
    int? shakeCount,
  }) =>
      GamePiece(
        id: id,
        cells: cells,
        direction: direction,
        isExiting: isExiting ?? this.isExiting,
        hasExited: hasExited ?? this.hasExited,
        shakeCount: shakeCount ?? this.shakeCount,
      );
}

class GameplayState {
  const GameplayState({
    required this.level,
    required this.pieces,
    required this.mistakes,
    required this.phase,
    required this.mockLifelines,
  });

  final LevelDefinition level;
  final List<GamePiece> pieces;
  final int mistakes;
  final GamePhase phase;
  final int mockLifelines; // stub — wire to LevelMapCubit / persistence later

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
        mockLifelines: 7,
      );

  GameplayState copyWith({
    List<GamePiece>? pieces,
    int? mistakes,
    GamePhase? phase,
    int? mockLifelines,
  }) =>
      GameplayState(
        level: level,
        pieces: pieces ?? this.pieces,
        mistakes: mistakes ?? this.mistakes,
        phase: phase ?? this.phase,
        mockLifelines: mockLifelines ?? this.mockLifelines,
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
    switch (piece.direction) {
      case Direction.right:
        for (int c = head.col + 1; c < level.cols; c++) {
          final other = pieceAt(head.row, c, includeExiting: true);
          if (other != null && other.id != piece.id) return false;
        }
      case Direction.left:
        for (int c = head.col - 1; c >= 0; c--) {
          final other = pieceAt(head.row, c, includeExiting: true);
          if (other != null && other.id != piece.id) return false;
        }
      case Direction.up:
        for (int r = head.row - 1; r >= 0; r--) {
          final other = pieceAt(r, head.col, includeExiting: true);
          if (other != null && other.id != piece.id) return false;
        }
      case Direction.down:
        for (int r = head.row + 1; r < level.rows; r++) {
          final other = pieceAt(r, head.col, includeExiting: true);
          if (other != null && other.id != piece.id) return false;
        }
    }
    return true;
  }
}
