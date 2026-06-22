import 'level_definition.dart';
import 'level_generator.dart';
import 'shape_masks.dart';
import 'solvability.dart';

// Cache so each level is only generated once per app session.
final _cache = <int, LevelDefinition>{};

/// Returns a deterministic, solvable [LevelDefinition] for level [n] (≥ 1).
///
/// Every 10th level is a special shaped puzzle — the shapes cycle:
///   10 → Heart   20 → Star   30 → Circle
///   40 → Diamond 50 → Cross  60 → Hexagon  (then repeats)
LevelDefinition levelForNumber(int n) {
  assert(n >= 1, 'Level number must be ≥ 1');
  return _cache.putIfAbsent(n, () => _build(n));
}

// Shape cycle for every-10th levels.
const _shapes = ShapeType.values; // heart, star, circle, diamond, cross, hexagon

LevelDefinition _build(int n) {
  final bool isSpecial = n % 10 == 0;

  final int grid;
  final int minTurns;
  final int maxTurns;
  final int maxStep;

  if (isSpecial) {
    // Shape levels always use a 26×26 grid so the shape has enough room.
    grid = 26; minTurns = 2; maxTurns = 4; maxStep = 5;
  } else if (n <= 10) {
    grid = 14; minTurns = 2; maxTurns = 3; maxStep = 4;
  } else if (n <= 30) {
    grid = 16; minTurns = 2; maxTurns = 4; maxStep = 4;
  } else if (n <= 60) {
    grid = 18; minTurns = 2; maxTurns = 4; maxStep = 5;
  } else if (n <= 100) {
    grid = 20; minTurns = 3; maxTurns = 5; maxStep = 5;
  } else if (n <= 150) {
    grid = 22; minTurns = 3; maxTurns = 5; maxStep = 5;
  } else if (n <= 200) {
    grid = 24; minTurns = 3; maxTurns = 6; maxStep = 6;
  } else {
    grid = 26; minTurns = 4; maxTurns = 6; maxStep = 6;
  }

  final baseSeed = n * 2_654_435_761 & 0xFFFFFFFF;

  // Shape mask for milestone levels.
  Set<String>? shapeMask;
  if (isSpecial) {
    final shapeIndex = (n ~/ 10 - 1) % _shapes.length;
    shapeMask = buildShapeMask(_shapes[shapeIndex], grid, grid);
  }

  // Try up to 8 seed variants. For shape levels the cycle-breaker can
  // occasionally get stuck; a fresh seed re-shuffles piece placement.
  LevelDefinition? best;
  for (int attempt = 0; attempt < 8; attempt++) {
    final seed = (baseSeed + attempt * 999_983) & 0xFFFFFFFF;
    final level = generateLevel(
      id: '$n',
      rows: grid, cols: grid,
      seed: seed,
      minTurns: minTurns, maxTurns: maxTurns,
      minStep: 2, maxStep: maxStep,
      shapeMask: shapeMask,
    );
    if (checkSolvability(level).isSolvable) return level;
    best ??= level; // keep first attempt as fallback
  }
  return best!;
}
