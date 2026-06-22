import 'level_generator.dart';

// Level 100 — 26×26 grid, ~50–70 pieces, 3–5 turns each.
// Hard complexity: longer pieces that wind more, denser blocking chains.
final kLevel100 = generateLevel(
  id: '100',
  rows: 26,
  cols: 26,
  seed: 9999,
  minTurns: 3,
  maxTurns: 5,
  minStep: 2,
  maxStep: 5,
);
