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
    this.shapeCells, // null = full rectangular grid
  });
  final String id;
  final int rows;
  final int cols;
  final List<PieceDefinition> pieces;

  /// Set of 'row,col' keys that make up the active shape.
  /// Null means the full grid is used.
  final Set<String>? shapeCells;

  int get expectedCells => shapeCells?.length ?? rows * cols;
}

