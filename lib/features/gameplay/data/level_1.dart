import 'level_definition.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LEVEL 1 — 20×40 grid, 100% packed (800 cells).
// Organic maze: irregular rectangular blocks of varying sizes, each filled
// with a serpentine winding path. Mixed arrow directions (↑ ↓ ← →).
//
// Grid partitioned into 6 column groups with staggered vertical splits:
//   Group A: cols 0-2   |  Group B: cols 3-6   |  Group C: cols 7-9
//   Group D: cols 10-12 |  Group E: cols 13-16 |  Group F: cols 17-19
//
// Solve cascade:
//   Wave 0 (14 pieces): border-touching pieces that always exit freely
//   Wave 1 (5 pieces):  unblocked after wave 0
//   Wave 2 (2 pieces):  unblocked after wave 1
// ─────────────────────────────────────────────────────────────────────────────

/// Generates a horizontal serpentine path filling a rectangular zone.
///
/// [reverseRows] = true traverses rows bottom→top (for UP exit).
/// [startLeftToRight] controls the zigzag direction of the first row.
List<GridPos> _serpentine({
  required int rStart,
  required int rEnd,
  required int cStart,
  required int cEnd,
  required bool startLeftToRight,
  bool reverseRows = false,
}) {
  final cells = <GridPos>[];
  final numRows = rEnd - rStart + 1;
  bool ltr = startLeftToRight;

  for (int i = 0; i < numRows; i++) {
    final r = reverseRows ? (rEnd - i) : (rStart + i);
    if (ltr) {
      for (int c = cStart; c <= cEnd; c++) {
        cells.add(GridPos(r, c));
      }
    } else {
      for (int c = cEnd; c >= cStart; c--) {
        cells.add(GridPos(r, c));
      }
    }
    ltr = !ltr;
  }
  return cells;
}

List<PieceDefinition> _generateMazePieces() {
  final pieces = <PieceDefinition>[];

  /// Helper: adds a serpentine piece for the given rectangular zone.
  /// Automatically computes startLTR and reverseRows from [dir].
  ///
  /// Head positions:
  ///   LEFT  → (rEnd, cStart)    RIGHT → (rEnd, cEnd)
  ///   UP    → (rStart, cStart)  DOWN  → (rEnd, cEnd)
  void add(String id, int rStart, int rEnd, int cStart, int cEnd, Direction dir) {
    final numRows = rEnd - rStart + 1;
    final reverse = (dir == Direction.up);

    // Choose startLTR so the LAST cell lands at the correct edge column.
    //   head at cStart (R→L last row) → startLTR = even numRows
    //   head at cEnd   (L→R last row) → startLTR = odd  numRows
    final wantCEnd = (dir == Direction.right || dir == Direction.down);
    final startLTR = wantCEnd ? (numRows % 2 == 1) : (numRows % 2 == 0);

    pieces.add(PieceDefinition(
      id: id,
      cells: _serpentine(
        rStart: rStart,
        rEnd: rEnd,
        cStart: cStart,
        cEnd: cEnd,
        startLeftToRight: startLTR,
        reverseRows: reverse,
      ),
      direction: dir,
    ));
  }

  // ── Group A: cols 0-2 (width 3, 120 cells) ──────────────────────────────
  add('A1',  0, 11,  0,  2, Direction.up);    // 12×3=36  head(0,0)  ↑ free
  add('A2', 12, 26,  0,  2, Direction.left);  // 15×3=45  head(26,0) ← free
  add('A3', 27, 39,  0,  2, Direction.down);  // 13×3=39  head(39,2) ↓ free

  // ── Group B: cols 3-6 (width 4, 160 cells) ──────────────────────────────
  add('B1',  0,  8,  3,  6, Direction.up);    //  9×4=36  head(0,3)  ↑ free
  add('B2',  9, 21,  3,  6, Direction.left);  // 13×4=52  head(21,3) ← blocked by A2
  add('B3', 22, 31,  3,  6, Direction.left);  // 10×4=40  head(31,3) ← blocked by A3
  add('B4', 32, 39,  3,  6, Direction.down);  //  8×4=32  head(39,6) ↓ free

  // ── Group C: cols 7-9 (width 3, 120 cells) ──────────────────────────────
  add('C1',  0, 13,  7,  9, Direction.up);    // 14×3=42  head(0,7)  ↑ free
  add('C2', 14, 24,  7,  9, Direction.left);  // 11×3=33  head(24,7) ← blocked by A2,B3
  add('C3', 25, 39,  7,  9, Direction.down);  // 15×3=45  head(39,9) ↓ free

  // ── Group D: cols 10-12 (width 3, 120 cells) ────────────────────────────
  add('D1',  0,  9, 10, 12, Direction.up);    // 10×3=30  head(0,10) ↑ free
  add('D2', 10, 24, 10, 12, Direction.right); // 15×3=45  head(24,12) → blocked by E3,F2
  add('D3', 25, 34, 10, 12, Direction.right); // 10×3=30  head(34,12) → blocked by E4,F3
  add('D4', 35, 39, 10, 12, Direction.down);  //  5×3=15  head(39,12) ↓ free

  // ── Group E: cols 13-16 (width 4, 160 cells) ────────────────────────────
  add('E1',  0, 11, 13, 16, Direction.up);    // 12×4=48  head(0,13) ↑ free
  add('E2', 12, 20, 13, 16, Direction.right); //  9×4=36  head(20,16) → blocked by F2
  add('E3', 21, 30, 13, 16, Direction.right); // 10×4=40  head(30,16) → blocked by F3
  add('E4', 31, 39, 13, 16, Direction.down);  //  9×4=36  head(39,16) ↓ free

  // ── Group F: cols 17-19 (width 3, 120 cells) ────────────────────────────
  add('F1',  0, 14, 17, 19, Direction.up);    // 15×3=45  head(0,17) ↑ free
  add('F2', 15, 27, 17, 19, Direction.right); // 13×3=39  head(27,19) → free
  add('F3', 28, 39, 17, 19, Direction.down);  // 12×3=36  head(39,19) ↓ free

  return pieces;
}

final kLevel1 = LevelDefinition(
  id: '1',
  rows: 40,
  cols: 20,
  pieces: _generateMazePieces(),
);
