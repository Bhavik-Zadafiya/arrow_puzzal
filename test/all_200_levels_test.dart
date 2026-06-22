import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_pussal/features/gameplay/data/level_service.dart';
import 'package:arrow_pussal/features/gameplay/data/solvability.dart';

void main() {
  final failures = <String>[];

  for (int n = 1; n <= 200; n++) {
    test('Level $n', () {
      final level  = levelForNumber(n);
      final result = checkSolvability(level);

      final shape = level.shapeCells != null
          ? ' [shape:${level.shapeCells!.length}cells]'
          : '';
      // ignore: avoid_print
      print('L$n${shape}: pieces=${result.totalPieces} '
          'cov=${result.totalCells}/${result.expectedCells} '
          'ok=${result.isSolvable} rounds=${result.rounds}');

      if (!result.isSolvable || result.totalCells != result.expectedCells) {
        failures.add('Level $n — solvable:${result.isSolvable} '
            'coverage:${result.totalCells}/${result.expectedCells} '
            'stuck:${result.stuckPieces.length}');
      }

      expect(result.totalCells, equals(result.expectedCells),
          reason: 'Level $n: grid not fully covered');
      expect(result.stuckPieces, isEmpty,
          reason: 'Level $n: ${result.stuckPieces.length} piece(s) stuck');
    });
  }

  tearDownAll(() {
    if (failures.isEmpty) {
      // ignore: avoid_print
      print('\n✓ ALL 200 LEVELS PASSED');
    } else {
      // ignore: avoid_print
      print('\n✗ FAILURES (${failures.length}):');
      for (final f in failures) {
        // ignore: avoid_print
        print('  $f');
      }
    }
  });
}
