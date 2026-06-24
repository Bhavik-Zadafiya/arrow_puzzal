import '../../../core/services/settings_service.dart';
import 'level_definition.dart';
import 'level_generator.dart';
import 'shape_masks.dart';
import 'solvability.dart';

// ── Public API ────────────────────────────────────────────────────────────────

/// Runtime cache — keyed by (levelNumber, difficultyLevel) so changing the
/// difficulty setting regenerates levels automatically.
final _cache = <String, LevelDefinition>{};

/// Call this whenever the user changes their difficulty preference.
void clearLevelCache() => _cache.clear();

/// Returns a deterministic, solvable [LevelDefinition] for level [n] (≥ 1).
/// Respects [SettingsService.instance.difficultyLevel] (1–10).
LevelDefinition levelForNumber(int n) {
  assert(n >= 1, 'Level number must be ≥ 1');
  final diff = SettingsService.instance.difficultyLevel;
  final key  = '$n:$diff';
  return _cache.putIfAbsent(key, () => _build(n, diff));
}

// ── Shape cycle ───────────────────────────────────────────────────────────────

const _shapes = ShapeType.values;

// ── Parameter curves ──────────────────────────────────────────────────────────
//
// The Settings "Puzzle Complexity" slider (1–10) is the PRIMARY difficulty knob.
// Default = 1 (very easy).  At 10 the puzzles are brutally large.
//
// Grid sizes at diff=1 vs diff=10 for sample levels:
//   Level 1  :  5×5   →  20×20
//   Level 10 :  6×6   →  25×25
//   Level 50 :  8×8   →  32×32
//   Level 100: 10×10  →  40×40
//   Level 500: 14×14  →  60×60
//
// Scaling is exponential so the step from 9→10 is as large as 1→5.

double _diffMult(int diff) {
  // diff=1 → 3.0, diff=10 → 7.0, linear.
  return 3.0 + (diff - 1) * (4.0 / 9.0);
}

int _grid(int n, int diff) {
  // Base grid: 5 at L1, grows to 20 at L500.
  final base = 5 + (n / 500.0) * 15;
  return (base * _diffMult(diff)).floor().clamp(5, 70);
}

int _minTurns(int n, int diff) {
  final base = 1 + (n / 500.0) * 3; // 1 → 4
  return (base * _diffMult(diff)).floor().clamp(1, 12);
}

int _maxTurns(int n, int diff) {
  final base = 2 + (n / 500.0) * 5; // 2 → 7
  return (base * _diffMult(diff)).floor().clamp(2, 16);
}

int _maxStep(int n, int diff) {
  final base = 2 + (n / 500.0) * 4; // 2 → 6
  return (base * _diffMult(diff)).floor().clamp(2, 12);
}

// ── Builder ───────────────────────────────────────────────────────────────────

LevelDefinition _build(int n, int diff) {
  final isSpecial  = n % 10 == 0;
  final grid       = isSpecial ? _grid(n, diff).clamp(14, 40) : _grid(n, diff);
  final minTurns   = _minTurns(n, diff);
  final maxTurns   = _maxTurns(n, diff);
  final maxStep    = _maxStep(n, diff);
  final baseSeed   = (n * 2_654_435_761) & 0xFFFFFFFF;

  Set<String>? shapeMask;
  if (isSpecial) {
    final idx = (n ~/ 10 - 1) % _shapes.length;
    shapeMask = buildShapeMask(_shapes[idx], grid, grid);
  }

  LevelDefinition? best;
  for (int attempt = 0; attempt < 20; attempt++) {
    final seed = (baseSeed + attempt * 999_983) & 0xFFFFFFFF;
    final level = generateLevel(
      id: '$n',
      rows: grid, cols: grid,
      seed: seed,
      minTurns: minTurns, maxTurns: maxTurns,
      minStep: 2, maxStep: maxStep,
      complexity: n,
      shapeMask: shapeMask,
    );
    if (checkSolvability(level).isSolvable) return level;
    best ??= level;
  }
  return best!;
}
