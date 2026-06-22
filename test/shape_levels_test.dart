import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_pussal/features/gameplay/data/level_service.dart';
import 'package:arrow_pussal/features/gameplay/data/solvability.dart';

void main() {
  for (final n in [10, 20, 30, 40, 50, 60]) {
    test('Level $n (shape) is solvable', () {
      final level  = levelForNumber(n);
      final result = checkSolvability(level);
      // ignore: avoid_print
      print('Level $n — ${level.shapeCells!.length} shape cells, '
          '${result.totalPieces} pieces, ${result.rounds} rounds');
      expect(level.shapeCells, isNotNull, reason: 'Level $n should have a shape');
      expect(result.totalCells, equals(result.expectedCells),
          reason: 'Level $n: coverage');
      expect(result.stuckPieces, isEmpty,
          reason: 'Level $n: solvable');
    });
  }
}
