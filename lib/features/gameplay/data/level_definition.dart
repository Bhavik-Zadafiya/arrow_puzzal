enum Direction { up, down, left, right }

class GridPos {
  const GridPos(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';
}

class PieceDefinition {
  const PieceDefinition({
    required this.id,
    required this.cells,
    required this.direction,
  });
  final String id;
  final List<GridPos> cells;
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

