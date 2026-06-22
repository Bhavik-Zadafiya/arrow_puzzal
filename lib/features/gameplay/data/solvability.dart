import 'level_definition.dart';

/// Result of a solvability simulation for a single level.
class SolvabilityResult {
  const SolvabilityResult({
    required this.isSolvable,
    required this.totalPieces,
    required this.stuckPieces,
    required this.rounds,
    required this.roundLog,
    required this.overlaps,
    required this.totalCells,
    required this.expectedCells,
  });

  final bool isSolvable;
  final int totalPieces;
  final Set<String> stuckPieces;
  final int rounds;
  final List<String> roundLog;
  final List<String> overlaps;
  final int totalCells;
  final int expectedCells;

  bool get hasOverlaps => overlaps.isNotEmpty;
  bool get isFullCoverage => totalCells == expectedCells;
}

/// Simulates solving [level] and returns a [SolvabilityResult].
SolvabilityResult checkSolvability(LevelDefinition level) {
  // ── Overlap check ────────────────────────────────────────────────────────
  final seen = <String, String>{};
  final overlaps = <String>[];
  for (final p in level.pieces) {
    for (final cell in p.cells) {
      final key = '${cell.row},${cell.col}';
      if (seen.containsKey(key)) {
        overlaps.add('Cell $key shared by ${seen[key]} & ${p.id}');
      } else {
        seen[key] = p.id;
      }
    }
  }

  final totalCells    = level.pieces.fold(0, (s, p) => s + p.cells.length);
  final expectedCells = level.expectedCells;

  // ── Solvability simulation ───────────────────────────────────────────────
  final cellOwner = <String, String>{};
  for (final p in level.pieces) {
    for (final cell in p.cells) {
      cellOwner['${cell.row},${cell.col}'] = p.id;
    }
  }

  final remaining = {for (final p in level.pieces) p.id: p};
  final roundLog  = <String>[];

  bool isFree(PieceDefinition p) {
    final head = p.cells.last;
    switch (p.direction) {
      case Direction.right:
        for (int c = head.col + 1; c < level.cols; c++) {
          final o = cellOwner['${head.row},$c'];
          if (o != null && o != p.id) return false;
        }
      case Direction.left:
        for (int c = head.col - 1; c >= 0; c--) {
          final o = cellOwner['${head.row},$c'];
          if (o != null && o != p.id) return false;
        }
      case Direction.up:
        for (int r = head.row - 1; r >= 0; r--) {
          final o = cellOwner['$r,${head.col}'];
          if (o != null && o != p.id) return false;
        }
      case Direction.down:
        for (int r = head.row + 1; r < level.rows; r++) {
          final o = cellOwner['$r,${head.col}'];
          if (o != null && o != p.id) return false;
        }
    }
    return true;
  }

  int rounds = 0;
  while (true) {
    final freed = remaining.values.where(isFree).toList();
    if (freed.isEmpty) break;
    rounds++;
    roundLog.add('Round $rounds: freed ${freed.length} piece(s)');
    for (final p in freed) {
      remaining.remove(p.id);
      for (final cell in p.cells) {
        cellOwner.remove('${cell.row},${cell.col}');
      }
    }
  }

  return SolvabilityResult(
    isSolvable: remaining.isEmpty,
    totalPieces: level.pieces.length,
    stuckPieces: remaining.keys.toSet(),
    rounds: rounds,
    roundLog: roundLog,
    overlaps: overlaps,
    totalCells: totalCells,
    expectedCells: expectedCells,
  );
}
