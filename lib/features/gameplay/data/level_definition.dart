enum Direction { up, down, left, right }

class PieceDefinition {
  const PieceDefinition({
    required this.row,
    required this.col,
    required this.direction,
  });
  final int row;
  final int col;
  final Direction direction;
}

class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.rows,
    required this.cols,
    required this.pieces,
  });
  final String id;
  final int rows;
  final int cols;
  final List<PieceDefinition> pieces;
}
