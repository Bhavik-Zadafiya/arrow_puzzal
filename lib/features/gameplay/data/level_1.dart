import 'level_definition.dart';

// 5×5 grid, 5 pieces.
// Dependency chain:
//   B (2,2)↑ must exit before C (2,4)←
//   D (3,1)↓ must exit before E (3,3)←
//   A (1,1)→ is always free
// Multiple valid orderings, 2 gentle blocks — suitable for Level 1.
const kLevel1 = LevelDefinition(
  id: '1',
  rows: 5,
  cols: 5,
  pieces: [
    PieceDefinition(row: 1, col: 1, direction: Direction.right), // A — always clear
    PieceDefinition(row: 2, col: 2, direction: Direction.up),    // B — always clear
    PieceDefinition(row: 2, col: 4, direction: Direction.left),  // C — blocked by B
    PieceDefinition(row: 3, col: 1, direction: Direction.down),  // D — always clear
    PieceDefinition(row: 3, col: 3, direction: Direction.left),  // E — blocked by D
  ],
);
