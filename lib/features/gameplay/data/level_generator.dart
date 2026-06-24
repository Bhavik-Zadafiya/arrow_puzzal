import 'level_definition.dart';

int _lcg(int s) => (s * 1664525 + 1013904223) & 0xFFFFFFFF;

Direction _exitDir(List<GridPos> cells) {
  if (cells.length < 2) return Direction.right;
  final p = cells[cells.length - 2];
  final h = cells.last;
  if (h.col > p.col) return Direction.right;
  if (h.col < p.col) return Direction.left;
  if (h.row > p.row) return Direction.down;
  return Direction.up;
}

const _allDirs = [Direction.right, Direction.left, Direction.up, Direction.down];

// Returns true when the cell immediately ahead of the head in [dir] is also
// part of the same piece — the arrowhead would visually point INTO the body.
bool _arrowPointsInward(List<GridPos> cells, Direction dir) {
  if (cells.isEmpty) return false;
  final head = cells.last;
  final nr = head.row + (dir == Direction.down  ? 1 : dir == Direction.up   ? -1 : 0);
  final nc = head.col + (dir == Direction.right ? 1 : dir == Direction.left ? -1 : 0);
  return cells.any((c) => c.row == nr && c.col == nc);
}

// ── Dependency helpers ────────────────────────────────────────────────────────

// IDs of every OTHER piece whose cells occupy cells.last's exit path in [dir].
Set<String> _depsOf(String pid, List<GridPos> cells, Direction dir,
    Map<String, String> owner, int rows, int cols) {
  final result = <String>{};
  int r = cells.last.row, c = cells.last.col;
  while (true) {
    switch (dir) {
      case Direction.right: c++; break;
      case Direction.left:  c--; break;
      case Direction.up:    r--; break;
      case Direction.down:  r++; break;
    }
    if (r < 0 || r >= rows || c < 0 || c >= cols) break;
    final o = owner['$r,$c'];
    if (o != null && o != pid) result.add(o);
  }
  return result;
}

// Full dependency map for the current piece list.
Map<String, Set<String>> _buildDeps(List<PieceDefinition> pieces,
    Map<String, String> owner, int rows, int cols) =>
    {for (final p in pieces) p.id: _depsOf(p.id, p.cells, p.direction, owner, rows, cols)};

// ── Cycle detection (iterative DFS — no recursion risk) ───────────────────────

List<String>? _findCycle(Map<String, Set<String>> deps) {
  // 0 = white, 1 = grey (on stack), 2 = black (done)
  final color  = <String, int>{};
  final parent = <String, String?>{};

  for (final start in deps.keys) {
    if ((color[start] ?? 0) != 0) continue;

    // Explicit stack: (node, iterator over its neighbours)
    final stack = <(String, Iterator<String>)>[];
    color[start] = 1;
    parent[start] = null;
    stack.add((start, (deps[start] ?? <String>{}).iterator));

    while (stack.isNotEmpty) {
      final (u, it) = stack.last;

      if (it.moveNext()) {
        final v = it.current;
        if ((color[v] ?? 0) == 0) {
          color[v] = 1;
          parent[v] = u;
          stack.add((v, (deps[v] ?? <String>{}).iterator));
        } else if (color[v] == 1) {
          // Back edge u→v: extract cycle v…u
          final cycle = <String>[u];
          String cur = u;
          while (cur != v) {
            cur = parent[cur]!;
            cycle.add(cur);
          }
          return cycle; // cycle members (order doesn't matter for our fix)
        }
      } else {
        color[u] = 2;
        stack.removeLast();
      }
    }
  }
  return null;
}

// ── Generator ─────────────────────────────────────────────────────────────────

LevelDefinition generateLevel({
  required String id,
  required int rows,
  required int cols,
  required int seed,
  int minTurns   = 2,
  int maxTurns   = 4,
  int minStep    = 2,
  int maxStep    = 5,
  int complexity = 0,
  Set<String>? shapeMask,
}) {
  var s = seed;
  int rng(int max) { s = _lcg(s); return s % max; }

  final occ = List.generate(rows, (_) => List.filled(cols, false));
  var pieces = <PieceDefinition>[];
  int idx = 0;

  const dr   = [0, 0, -1, 1];
  const dc   = [1, -1,  0, 0];
  const dirs = [Direction.right, Direction.left, Direction.up, Direction.down];

  bool inShape(int r, int c) =>
      shapeMask == null || shapeMask.contains('$r,$c');

  bool free(int r, int c) =>
      r >= 0 && r < rows && c >= 0 && c < cols && !occ[r][c] && inShape(r, c);

  // ── 1. Place pieces ────────────────────────────────────────────────────────

  for (int sr = 0; sr < rows; sr++) {
    for (int sc = 0; sc < cols; sc++) {
      if (occ[sr][sc] || !inShape(sr, sc)) continue;

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
        final isH   = dir <= 1;
        final pA    = isH ? 2 : 0;
        final pB    = isH ? 3 : 1;
        final first = rng(2) == 0 ? pA : pB;
        final sec   = (first == pA) ? pB : pA;
        if (free(r + dr[first], c + dc[first])) {
          dir = first;
        } else if (free(r + dr[sec], c + dc[sec])) {
          dir = sec;
        } else {
          break;
        }
      }
      final fs = minStep + rng(maxStep - minStep + 1);
      for (int k = 0; k < fs; k++) {
        final nr = r + dr[dir], nc = c + dc[dir];
        if (!free(nr, nc)) break;
        r = nr; c = nc;
        occ[r][c] = true;
        cells.add(GridPos(r, c));
      }
      // Try to guarantee at least 2 cells — a 1-cell piece looks like a bare arrowhead.
      if (cells.length == 1) {
        for (int d2 = 0; d2 < 4; d2++) {
          final nr = sr + dr[d2], nc = sc + dc[d2];
          if (free(nr, nc)) {
            occ[nr][nc] = true;
            cells.add(GridPos(nr, nc));
            dir = d2;
            break;
          }
        }
        // If still 1 cell (fully surrounded), keep it — the painter draws a stub tail.
      }

      // After all turns, count how many consecutive cells trail the path in the
      // current exit direction.  If < 2, try to extend so the tip has context.
      if (cells.length >= 2) {
        final exitD = dirs[dir];
        int tailLen = 0;
        for (int i = cells.length - 1; i >= 1; i--) {
          final a = cells[i - 1], b = cells[i];
          final segDir = (b.col > a.col) ? Direction.right
              : (b.col < a.col) ? Direction.left
              : (b.row > a.row) ? Direction.down : Direction.up;
          if (segDir == exitD) { tailLen++; } else { break; }
        }
        if (tailLen < 2) {
          // Try to append 1 more cell in the exit direction.
          final nr = r + dr[dir], nc = c + dc[dir];
          if (free(nr, nc)) {
            occ[nr][nc] = true;
            cells.add(GridPos(nr, nc));
          }
        }
      }

      // Derive exit direction from geometry. If it points back into the body
      // (U-turn / enclosed shape), try the reversed traversal instead.
      List<GridPos> finalCells = cells;
      Direction exitDirection;
      if (cells.length >= 2) {
        final fwdDir = _exitDir(cells);
        final rev    = cells.reversed.toList();
        final revDir = _exitDir(rev);
        if (_arrowPointsInward(cells, fwdDir) && !_arrowPointsInward(rev, revDir)) {
          finalCells    = rev;
          exitDirection = revDir;
        } else {
          exitDirection = fwdDir;
        }
      } else {
        exitDirection = dirs[dir];
      }
      pieces.add(PieceDefinition(id: '${idx++}', cells: finalCells, direction: exitDirection));
    }
  }

  // ── 2. Break all dependency cycles ────────────────────────────────────────
  //
  // Why the previous approach failed:
  //   "exitClear" checked whether the path is IMMEDIATELY clear right now.
  //   In a fully-packed grid almost nothing is immediately clear, so the
  //   fixer never made progress.
  //
  // Correct approach — dependency cycle breaking:
  //   Build a directed graph where A→B means "A must wait for B to exit first"
  //   (B's cells are in A's exit path).  A puzzle is solvable iff this graph
  //   is a DAG.  For every cycle found, redirect one piece so it no longer
  //   depends on another cycle member — concretely, pick the (cells, dir)
  //   option from 9 candidates that minimises the number of cycle-member
  //   dependencies.  Repeat until the graph is cycle-free.
  //
  // Cell positions never change (only direction / traversal order), so
  // the owner map is built once and stays valid throughout.

  final owner = <String, String>{};
  for (final p in pieces) {
    for (final cell in p.cells) {
      owner['${cell.row},${cell.col}'] = p.id;
    }
  }

  // The 9 candidate (cells, direction) combos to try for a piece.
  List<(List<GridPos>, Direction)> candidates(PieceDefinition p) {
    final fwd = p.cells;
    final rev = p.cells.reversed.toList();
    return [
      (rev, _exitDir(rev)),                        // reverse, natural dir
      for (final d in _allDirs) (fwd, d),          // forward, forced dir
      for (final d in _allDirs) (rev, d),          // reverse, forced dir
    ];
  }

  // Use a visited-state set to detect if we've truly stopped making progress.
  final seenStates = <String>{};

  for (int pass = 0; pass < pieces.length * pieces.length; pass++) {
    final deps  = _buildDeps(pieces, owner, rows, cols);
    final cycle = _findCycle(deps);
    if (cycle == null) break; // ✓ no cycles — puzzle is solvable

    // Fingerprint the current assignment so we can detect infinite loops.
    final stateKey = pieces.map((p) => '${p.id}:${p.direction.index}:${p.cells.last.row},${p.cells.last.col}').join('|');
    if (!seenStates.add(stateKey)) break; // seen this exact state before → stuck

    final cycleSet = cycle.toSet();

    // Scan EVERY cycle member and pick the best (cells, dir) candidate.
    // Score = cd*2 + mismatch:  lower is better.
    //   cd       = number of cycle-member dependencies (primary: must be 0 to break cycle)
    //   mismatch = 1 if _exitDir(cells) != dir (visually wrong), 0 if correct
    // Ties on cd go to the visually-correct candidate automatically.
    String? bestPieceId;
    int?    bestPieceIdx;
    List<GridPos>? bestCells;
    Direction?     bestDir;
    int bestScore = 9999;

    for (final cid in cycle) {
      final i = pieces.indexWhere((p) => p.id == cid);
      final p = pieces[i];

      for (final (cells, dir) in candidates(p)) {
        final newDeps  = _depsOf(p.id, cells, dir, owner, rows, cols);
        final cd       = newDeps.where(cycleSet.contains).length;
        final mismatch = _exitDir(cells) != dir ? 1 : 0;
        final inward   = _arrowPointsInward(cells, dir) ? 3 : 0;
        final score    = cd * 2 + mismatch + inward;
        if (score < bestScore) {
          bestScore    = score;
          bestPieceId  = cid;
          bestPieceIdx = i;
          bestCells    = cells;
          bestDir      = dir;
          if (score == 0) break; // cd=0 AND visually correct — perfect
        }
      }
      if (bestScore == 0) break; // already perfect across all members
    }

    // Apply the best redirect found — always commit (even partial improvement
    // shifts the graph and lets the next pass make more progress).
    if (bestPieceIdx != null && bestCells != null && bestDir != null) {
      pieces[bestPieceIdx] = PieceDefinition(
        id: bestPieceId ?? '',
        cells: bestCells,
        direction: bestDir,
      );
    }
  }

  // ── 3. Post-process: fix direction/path mismatches without breaking cycles ───
  //
  // The cycle-breaker may have left pieces where direction != _exitDir(cells),
  // causing the arrowhead to visually point the wrong way.
  //
  // Try all four visually-correct (cells, direction) combos in priority order,
  // accepting the first one that keeps the dep-graph cycle-free.
  // Run multiple passes — each pass can unlock fixes the previous couldn't,
  // because fixing one piece changes the dep-graph for its neighbours.
  for (int pass = 0; pass < 3; pass++) {
    bool anyFixed = false;

    for (int i = 0; i < pieces.length; i++) {
      final p      = pieces[i];
      final fwd    = p.cells;
      final rev    = p.cells.reversed.toList();
      final fwdDir = _exitDir(fwd);
      final revDir = _exitDir(rev);

      // Skip if already visually correct AND tip doesn't point into the body.
      if (fwdDir == p.direction && !_arrowPointsInward(fwd, p.direction)) continue;

      for (final candidate in [
        PieceDefinition(id: p.id, cells: rev, direction: revDir),
        PieceDefinition(id: p.id, cells: fwd, direction: fwdDir),
      ]) {
        if (_exitDir(candidate.cells) != candidate.direction) continue;
        // Never accept a candidate whose tip points back into the piece body.
        if (_arrowPointsInward(candidate.cells, candidate.direction)) continue;
        pieces[i] = candidate;
        if (_findCycle(_buildDeps(pieces, owner, rows, cols)) == null) {
          anyFixed = true;
          break; // this piece is fixed — move to next
        }
        pieces[i] = p; // revert
      }
    }

    if (!anyFixed) break; // no progress this pass — stop early
  }

  return LevelDefinition(id: id, rows: rows, cols: cols, pieces: pieces,
      shapeCells: shapeMask, complexity: complexity);
}
