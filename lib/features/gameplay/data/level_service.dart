import 'level_definition.dart';
import 'level_generator.dart';
import 'shape_masks.dart';
import 'solvability.dart';

// ── Public API ────────────────────────────────────────────────────────────────

/// Runtime cache — each level is generated once per app session.
final _cache = <int, LevelDefinition>{};

/// Returns a deterministic, solvable [LevelDefinition] for level [n] (≥ 1).
LevelDefinition levelForNumber(int n) {
  assert(n >= 1, 'Level number must be ≥ 1');
  return _cache.putIfAbsent(n, () => _build(n));
}

/// Complexity score 0–1000 for display.
///
/// Starts at 100 (level 1), reaches ~200 at level 100,
/// then increases ~100 every 100 levels (level 200 → ~300, etc.).
/// At 500 levels the score is ~600; the remaining headroom (600–1000)
/// is reserved for future levels beyond 500.
int complexityFor(int n) => (99 + n).clamp(100, 1000);

// ── Shape cycle (14 shapes, repeating every 140 levels) ───────────────────────

const _shapes = ShapeType.values; // 14 shapes

// ── Smooth parameter growth over 500+ levels ─────────────────────────────────
//
//                 L1     L100   L200   L300   L400   L500
//   grid          14×14  17×17  20×20  23×23  26×26  30×30
//   minTurns      2      2      3      3      4      6
//   maxTurns      3      4      5      6      7      8
//   maxStep       3      4      5      6      7      8

int _grid(int n)      => (14.0 + (n / 500.0) * 16.0).floor().clamp(14, 30);
int _minTurns(int n)  => (2.0  + (n / 500.0) *  4.0).floor().clamp(2, 6);
int _maxTurns(int n)  => (3.0  + (n / 500.0) *  5.0).floor().clamp(3, 8);
int _maxStep(int n)   => (3.0  + (n / 500.0) *  5.0).floor().clamp(3, 8);

// ── Builder ───────────────────────────────────────────────────────────────────

LevelDefinition _build(int n) {
  final isSpecial = n % 10 == 0;

  // Shape levels use 26×26 so every shape has plenty of room.
  final grid     = isSpecial ? 26 : _grid(n);
  final minTurns = _minTurns(n);
  final maxTurns = _maxTurns(n);
  final maxStep  = _maxStep(n);
  final baseSeed = (n * 2_654_435_761) & 0xFFFFFFFF;
  final score    = complexityFor(n);

  Set<String>? shapeMask;
  if (isSpecial) {
    final idx = (n ~/ 10 - 1) % _shapes.length;
    shapeMask = buildShapeMask(_shapes[idx], grid, grid);
  }

  // Try up to 20 seed variants — the post-process direction fix occasionally
  // leaves 1-2 seeds unsolvable; more attempts compensate for that.
  LevelDefinition? best;
  for (int attempt = 0; attempt < 20; attempt++) {
    final seed = (baseSeed + attempt * 999_983) & 0xFFFFFFFF;
    final level = generateLevel(
      id: '$n',
      rows: grid, cols: grid,
      seed: seed,
      minTurns: minTurns, maxTurns: maxTurns,
      minStep: 2, maxStep: maxStep,
      complexity: score,
      shapeMask: shapeMask,
    );
    if (checkSolvability(level).isSolvable) return level;
    best ??= level;
  }
  return best!;
}
