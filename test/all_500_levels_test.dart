import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_pussal/features/gameplay/data/level_service.dart';
import 'package:arrow_pussal/features/gameplay/data/solvability.dart';

void main() {
  final failures = <String>[];

  for (int n = 1; n <= 500; n++) {
    test('Level $n', () {
      final level  = levelForNumber(n);
      final result = checkSolvability(level);

      final tag = level.shapeCells != null
          ? ' [shape ${level.shapeCells!.length}c]' : '';
      // ignore: avoid_print
      print('L$n$tag  cplx=${level.complexity}  '
          '${level.rows}×${level.cols}  '
          'pieces=${result.totalPieces}  '
          'cov=${result.totalCells}/${result.expectedCells}  '
          'ok=${result.isSolvable}  rounds=${result.rounds}');

      if (!result.isSolvable || result.totalCells != result.expectedCells) {
        failures.add('Level $n — solvable:${result.isSolvable} '
            'coverage:${result.totalCells}/${result.expectedCells}');
      }

      expect(result.totalCells, equals(result.expectedCells),
          reason: 'Level $n not fully covered');
      expect(result.stuckPieces, isEmpty,
          reason: 'Level $n: ${result.stuckPieces.length} stuck');
    });
  }

  tearDownAll(() {
    if (failures.isEmpty) {
      // ignore: avoid_print
      print('\n✓ ALL 500 LEVELS PASSED');
    } else {
      // ignore: avoid_print
      print('\n✗ FAILURES (${failures.length}):');
      for (final f in failures) { // ignore: avoid_print
        print('  $f');
      }
    }
  });
}
