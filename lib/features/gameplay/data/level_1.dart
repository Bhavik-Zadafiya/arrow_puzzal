import 'level_generator.dart';

// Level 1 — 20×20 grid, ~30–40 pieces, 2–3 turns each.
// Easy complexity: shorter pieces, wider variety of directions.
final kLevel1 = generateLevel(
  id: '1',
  rows: 20,
  cols: 20,
  seed: 1337,
  minTurns: 2,
  maxTurns: 3,
  minStep: 2,
  maxStep: 4,
);
