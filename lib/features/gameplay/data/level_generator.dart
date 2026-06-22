import 'level_definition.dart';

// 32-bit LCG.
int _lcg(int s) => (s * 1664525 + 1013904223) & 0xFFFFFFFF;

// Exit direction inferred from the last two cells.
Direction _exitDir(List<GridPos> cells) {
  if (cells.length < 2) return Direction.right;
  final p = cells[cells.length - 2];
  final h = cells.last;
  if (h.col > p.col) return Direction.right;
  if (h.col < p.col) return Direction.left;
  if (h.row > p.row) return Direction.down;
  return Direction.up;
}

const _allDirs = [
  Direction.right, Direction.left,
  Direction.up,    Direction.down,
];

// ─── Solvability simulation ───────────────────────────────────────────────────
//
// Mimics gameplay: find every piece whose exit row/col is clear of all other
// remaining pieces, remove them, repeat.  Returns IDs still stuck (in cycles).

Set<String> _stuckPieceIds(
    List<PieceDefinition> pieces, int rows, int cols) {
  // cell-key → owner-id
  final cellOwner = <String, String>{};
  for (final p in pieces) {
    for (final cell in p.cells) {
      cellOwner['${cell.row},${cell.col}'] = p.id;
    }
  }

  final rem = {for (final p in pieces) p.id: p};

  bool isFree(PieceDefinition p) {
    final head = p.cells.last;
    switch (p.direction) {
      case Direction.right:
        for (int c = head.col + 1; c < cols; c++) {
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
        for (int r = head.row + 1; r < rows; r++) {
          final o = cellOwner['$r,${head.col}'];
          if (o != null && o != p.id) return false;
        }
    }
    return true;
  }

  while (true) {
    final freed = rem.values.where(isFree).toList();
    if (freed.isEmpty) break;
    for (final p in freed) {
      rem.remove(p.id);
      for (final cell in p.cells) {
        cellOwner.remove('${cell.row},${cell.col}');
      }
    }
  }

  return rem.keys.toSet();
}

// ─── Generator ───────────────────────────────────────────────────────────────

LevelDefinition generateLevel({
  required String id,
  required int rows,
  required int cols,
  required int seed,
  int minTurns = 2,
  int maxTurns = 4,
  int minStep  = 2,
  int maxStep  = 5,
}) {
  var s = seed;
  int rng(int max) { s = _lcg(s); return s % max; }

  final occ = List.generate(rows, (_) => List.filled(cols, false));
  var pieces = <PieceDefinition>[];
  int idx = 0;

  const dr   = [0, 0, -1, 1];
  const dc   = [1, -1,  0, 0];
  const dirs = [Direction.right, Direction.left, Direction.up, Direction.down];

  bool free(int r, int c) =>
      r >= 0 && r < rows && c >= 0 && c < cols && !occ[r][c];

  // ── 1. Generate raw pieces ─────────────────────────────────────────────────

  for (int sr = 0; sr < rows; sr++) {
    for (int sc = 0; sc < cols; sc++) {
      if (occ[sr][sc]) continue;

      occ[sr][sc] = true;
      final cells = <GridPos>[GridPos(sr, sc)];
      var r = sr, c = sc;
      var dir = rng(4);

      final numTurns = minTurns + rng(maxTurns - minTurns + 1);

      for (int t = 0; t < numTurns; t++) {
        final steps = minStep + rng(maxStep - minStep + 1);
        for (int k = 0; k < steps; k++) {
          final nr = r + dr[dir], nc = c + dc[dir];
          if (!free(nr, nc)) break;
          r = nr; c = nc;
          occ[r][c] = true;
          cells.add(GridPos(r, c));
        }

        final isH    = dir <= 1;
        final perpA  = isH ? 2 : 0;
        final perpB  = isH ? 3 : 1;
        final first  = rng(2) == 0 ? perpA : perpB;
        final second = (first == perpA) ? perpB : perpA;

        if (free(r + dr[first], c + dc[first])) {
          dir = first;
        } else if (free(r + dr[second], c + dc[second])) {
          dir = second;
        } else {
          break;
        }
      }

      final finalSteps = minStep + rng(maxStep - minStep + 1);
      for (int k = 0; k < finalSteps; k++) {
        final nr = r + dr[dir], nc = c + dc[dir];
        if (!free(nr, nc)) break;
        r = nr; c = nc;
        occ[r][c] = true;
        cells.add(GridPos(r, c));
      }

      pieces.add(PieceDefinition(
        id: '${idx++}',
        cells: cells,
        direction: dirs[dir],
      ));
    }
  }

  // ── 2. Guarantee solvability ───────────────────────────────────────────────
  //
  // Problem: purely random generation creates deadlock CYCLES of any length
  // (A→B→C→A).  Simple 2-cycle reversal misses longer chains, and for
  // symmetric snake pieces reversing keeps the same exit direction.
  //
  // Strategy: simulate the full solve.  For every "stuck" set found, locate
  // one piece we can make immediately free by trying (in order):
  //   a) reverse cells + natural new direction
  //   b) keep cells + any of the 4 directions
  //   c) reverse cells + any of the 4 directions
  // Pick the first combo whose exit from the head cell is currently clear.
  // After each fix re-simulate; repeat until fully solvable.
  //
  // Cell positions never change (only cell order / direction), so we build
  // cellOwner once and reuse it.

  final cellOwner = <String, String>{};
  for (final p in pieces) {
    for (final cell in p.cells) {
      cellOwner['${cell.row},${cell.col}'] = p.id;
    }
  }

  // Is the exit from p.cells.last in [dir] clear of all OTHER pieces?
  bool exitClear(String pid, List<GridPos> cells, Direction dir) {
    int r = cells.last.row, c = cells.last.col;
    while (true) {
      switch (dir) {
        case Direction.right: c++; break;
        case Direction.left:  c--; break;
        case Direction.up:    r--; break;
        case Direction.down:  r++; break;
      }
      if (r < 0 || r >= rows || c < 0 || c >= cols) return true; // reached edge
      final owner = cellOwner['$r,$c'];
      if (owner != null && owner != pid) return false;
    }
  }

  for (int pass = 0; pass < pieces.length; pass++) {
    final stuck = _stuckPieceIds(pieces, rows, cols);
    if (stuck.isEmpty) break; // ✓ solvable

    bool madeProgress = false;

    for (int i = 0; i < pieces.length && !madeProgress; i++) {
      final p = pieces[i];
      if (!stuck.contains(p.id)) continue;

      final fwdCells = p.cells;
      final revCells = p.cells.reversed.toList();
      final revDir   = _exitDir(revCells);

      // Candidates to try — (cells, direction) pairs ordered by visual quality:
      //   first prefer reversing with natural direction (cleanest look),
      //   then changing direction on either end.
      final candidates = <(List<GridPos>, Direction)>[
        (revCells, revDir),
        ...[ for (final d in _allDirs) (fwdCells, d) ],
        ...[ for (final d in _allDirs) (revCells, d) ],
      ];

      for (final (cells, dir) in candidates) {
        if (exitClear(p.id, cells, dir)) {
          pieces[i] = PieceDefinition(id: p.id, cells: cells, direction: dir);
          madeProgress = true;
          break;
        }
      }
    }

    if (!madeProgress) break; // No fixable piece found (shouldn't happen)
  }

  return LevelDefinition(id: id, rows: rows, cols: cols, pieces: pieces);
}
