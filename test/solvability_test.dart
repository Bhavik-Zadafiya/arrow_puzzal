import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_pussal/features/gameplay/data/level_1.dart';
import 'package:arrow_pussal/features/gameplay/data/level_100.dart';
import 'package:arrow_pussal/features/gameplay/data/solvability.dart';

void main() {
  for (final entry in [
    ('Level 1',   kLevel1),
    ('Level 100', kLevel100),
  ]) {
    final (name, level) = entry;

    group(name, () {
      late SolvabilityResult result;
      setUpAll(() { result = checkSolvability(level); });

      test('no overlapping cells', () {
        if (result.overlaps.isNotEmpty) {
          // ignore: avoid_print
          print('OVERLAPS:\n  ${result.overlaps.join('\n  ')}');
        }
        expect(result.overlaps, isEmpty,
            reason: '$name has overlapping cells between pieces');
      });

      test('grid fully covered', () {
        // ignore: avoid_print
        print('$name: ${result.totalCells} / ${result.expectedCells} cells '
            '(${level.pieces.length} pieces)');
        expect(result.totalCells, equals(result.expectedCells),
            reason: '$name covers ${result.totalCells} of ${result.expectedCells} cells');
      });

      test('is solvable', () {
        // ignore: avoid_print
        print('\n$name solvability trace '
            '(${level.pieces.length} pieces, ${level.rows}×${level.cols}):');
        for (final line in result.roundLog) {
          // ignore: avoid_print
          print('  $line');
        }
        if (result.stuckPieces.isNotEmpty) {
          // ignore: avoid_print
          print('  STUCK: ${result.stuckPieces}');
        } else {
          // ignore: avoid_print
          print('  ✓ All pieces freed — puzzle is solvable.');
        }
        expect(result.stuckPieces, isEmpty,
            reason: '$name has ${result.stuckPieces.length} piece(s) in deadlock');
      });
    });
  }
}
