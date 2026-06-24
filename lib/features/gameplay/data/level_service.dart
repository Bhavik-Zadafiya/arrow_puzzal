import 'dart:math' as _m;

import '../../../core/services/progress_service.dart';
import '../../../core/services/settings_service.dart';
import 'level_definition.dart';
import 'level_generator.dart';
import 'shape_masks.dart';
import 'solvability.dart';

// ── Public API ────────────────────────────────────────────────────────────────

/// Runtime cache — keyed by (levelNumber, effectiveDifficulty).
final _cache = <String, LevelDefinition>{};

void clearLevelCache() => _cache.clear();

/// Returns a deterministic, solvable [LevelDefinition] for level [n] (≥ 1).
/// The difficulty setting is ignored for levels 1–50 (locked natural ramp).
LevelDefinition levelForNumber(int n) {
  assert(n >= 1, 'Level number must be ≥ 1');
  final diff = _effectiveDiff(n);
  final key  = '$n:$diff';
  return _cache.putIfAbsent(key, () => _build(n, diff));
}

/// Difficulty setting is locked at 1 until the player completes level 50.
int _effectiveDiff(int n) {
  if (ProgressService.instance.highestUnlocked < 51) return 1;
  return SettingsService.instance.difficultyLevel;
}

/// Hardcoded 5×5 tutorial level — 4 arrows, all immediately solvable.
/// Layout (row, col):
///   P1 (0,1) → right   P2 (1,4) ↑ up
///   P3 (4,2) ← left    P4 (2,0) ↓ down
LevelDefinition tutorialLevel() => const LevelDefinition(
  id: 'tutorial',
  rows: 5,
  cols: 5,
  complexity: 0,
  pieces: [
    PieceDefinition(id: 'tp1', cells: [GridPos(0, 1)], direction: Direction.right),
    PieceDefinition(id: 'tp2', cells: [GridPos(1, 4)], direction: Direction.up),
    PieceDefinition(id: 'tp3', cells: [GridPos(4, 2)], direction: Direction.left),
    PieceDefinition(id: 'tp4', cells: [GridPos(2, 0)], direction: Direction.down),
  ],
);

// ── Shape cycle ───────────────────────────────────────────────────────────────

const _shapes = ShapeType.values;

// ── Natural progression curves ────────────────────────────────────────────────
//
// Level number drives a logarithmic ramp — fast growth early, gentle later.
// The Settings "Puzzle Complexity" slider adds an additive bonus on top.
//
// Natural grid sizes (diff=1):
//   Level  1  →  5×5    (just 2–3 arrows, very short paths)
//   Level  5  →  6×6
//   Level 10  →  7×7
//   Level 20  →  9×9
//   Level 50  → 11×11
//   Level 100 → 14×14
//   Level 200 → 17×17
//   Level 500 → 22×22
//
// Max difficulty (diff=10) adds +8 cells, more turns, longer steps.

/// Logarithmic interpolation from [lo] at n=1 to [hi] at n=500.
double _logCurve(int n, double lo, double hi) {
  final t = _m.log(n.toDouble()) / _m.log(500.0);
  return lo + (hi - lo) * t.clamp(0.0, 1.0);
}

/// Additive bonus from difficulty setting: 0 at diff=1, +8 at diff=10.
int _diffBonus(int diff) => ((diff - 1) * (8.0 / 9.0)).round();

int _grid(int n, int diff) {
  final base = _logCurve(n, 5.0, 22.0);
  return (base + _diffBonus(diff)).round().clamp(5, 60);
}

int _minTurns(int n, int diff) {
  final base = _logCurve(n, 2.0, 8.0);
  return (base + _diffBonus(diff) * 0.3).floor().clamp(2, 14);
}

int _maxTurns(int n, int diff) {
  final base = _logCurve(n, 3.0, 14.0);
  return (base + _diffBonus(diff) * 0.5).floor().clamp(3, 20);
}

int _maxStep(int n, int diff) {
  final base = _logCurve(n, 2.0, 7.0);
  return (base + _diffBonus(diff) * 0.25).floor().clamp(2, 12);
}

// ── Builder ───────────────────────────────────────────────────────────────────

LevelDefinition _build(int n, int diff) {
  final isSpecial  = n % 10 == 0;
  final grid       = isSpecial ? _grid(n, diff).clamp(12, 40) : _grid(n, diff);
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
