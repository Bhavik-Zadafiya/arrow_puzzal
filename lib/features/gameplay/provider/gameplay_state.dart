import '../data/level_definition.dart';

enum GamePhase { playing, failed, levelComplete }

class GamePiece {
  const GamePiece({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.isExiting = false,
    this.hasExited = false,
    this.shakeCount = 0,
  });

  final String id;
  final int row;
  final int col;
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
        row: row,
        col: col,
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
            .asMap()
            .entries
            .map((e) => GamePiece(
                  id: 'p${e.key}',
                  row: e.value.row,
                  col: e.value.col,
                  direction: e.value.direction,
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

  GamePiece? pieceAt(int row, int col) {
    for (final p in pieces) {
      if (p.isActive && p.row == row && p.col == col) return p;
    }
    return null;
  }

  bool isPathClear(GamePiece piece) {
    switch (piece.direction) {
      case Direction.right:
        for (int c = piece.col + 1; c < level.cols; c++) {
          if (pieceAt(piece.row, c) != null) return false;
        }
      case Direction.left:
        for (int c = piece.col - 1; c >= 0; c--) {
          if (pieceAt(piece.row, c) != null) return false;
        }
      case Direction.up:
        for (int r = piece.row - 1; r >= 0; r--) {
          if (pieceAt(r, piece.col) != null) return false;
        }
      case Direction.down:
        for (int r = piece.row + 1; r < level.rows; r++) {
          if (pieceAt(r, piece.col) != null) return false;
        }
    }
    return true;
  }
}
