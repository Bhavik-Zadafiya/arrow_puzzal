import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../gameplay/data/level_definition.dart';
import '../../gameplay/data/level_service.dart';
import '../../gameplay/data/solvability.dart';

/// Developer-only panel accessible from the level map.
/// Shows complexity table and lets the developer spot-validate any level.
class DevMapDialog extends StatefulWidget {
  const DevMapDialog({super.key});

  @override
  State<DevMapDialog> createState() => _DevMapDialogState();
}

class _DevMapDialogState extends State<DevMapDialog> {
  final _ctrl = TextEditingController(text: '1');
  String? _result;
  bool _testing = false;

  // Quick-look: complexity & params for a spread of levels.
  static const _preview = [1, 10, 50, 100, 200, 300, 400, 500];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _testLevel(int n) async {
    setState(() { _testing = true; _result = null; });
    final level  = levelForNumber(n.clamp(1, 9999));
    final result = await compute(_check, level);
    if (!mounted) return;
    final buf = StringBuffer();
    buf.writeln('Level $n  [complexity ${level.complexity}/1000]');
    buf.writeln('Grid     : ${level.rows}×${level.cols}');
    buf.writeln('Pieces   : ${result.totalPieces}');
    buf.writeln('Coverage : ${result.totalCells}/${result.expectedCells}');
    buf.writeln('Solvable : ${result.isSolvable ? "✓ YES (${result.rounds} rounds)" : "✗ NO"}');
    if (level.shapeCells != null) {
      buf.writeln('Shape    : ${level.shapeCells!.length} cells');
    }
    if (!result.isSolvable) {
      buf.writeln('Stuck    : ${result.stuckPieces.join(", ")}');
    }
    setState(() { _testing = false; _result = buf.toString(); });
  }

  Future<void> _copyResult() async {
    if (_result == null) return;
    await Clipboard.setData(ClipboardData(text: _result!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF2A5C45)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Column(
          children: [
            // Title
            _header(),
            // Complexity table
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _complexityTable(),
                    const SizedBox(height: 14),
                    _testPanel(),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.boardSurface,
                        foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.boardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
              bottom: BorderSide(
                  color: AppColors.accentGold.withValues(alpha: 0.3))),
        ),
        child: const Row(
          children: [
            Icon(Icons.bug_report, color: Color(0xFFFFD700), size: 20),
            SizedBox(width: 8),
            Text('Developer Panel',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      );

  Widget _complexityTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Complexity curve (out of 1000)',
            style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(height: 6),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FixedColumnWidth(80),
            2: FixedColumnWidth(70),
            3: FlexColumnWidth(),
          },
          children: [
            _tableRow(['Level', 'Score/1000', 'Grid', 'Turns/Step'],
                header: true),
            for (final n in _preview)
              _tableRow([
                '$n',
                '${complexityFor(n)}',
                '${_gridFor(n)}×${_gridFor(n)}',
                '${_minTurnsFor(n)}–${_maxTurnsFor(n)} / ${_maxStepFor(n)}',
              ]),
          ],
        ),
      ],
    );
  }

  // Expose internal helpers for the table (mirrors level_service internals)
  static int _gridFor(int n)     => n % 10 == 0 ? 26 : (14.0 + (n / 500.0) * 16.0).floor().clamp(14, 30);
  static int _minTurnsFor(int n) => (2.0 + (n / 500.0) * 4.0).floor().clamp(2, 6);
  static int _maxTurnsFor(int n) => (3.0 + (n / 500.0) * 5.0).floor().clamp(3, 8);
  static int _maxStepFor(int n)  => (3.0 + (n / 500.0) * 5.0).floor().clamp(3, 8);

  TableRow _tableRow(List<String> cells, {bool header = false}) {
    return TableRow(
      children: cells.map((t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Text(t,
            style: TextStyle(
                color: header
                    ? AppColors.accentGold
                    : Colors.white70,
                fontSize: 11,
                fontWeight:
                    header ? FontWeight.bold : FontWeight.normal)),
      )).toList(),
    );
  }

  Widget _testPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Validate a level',
            style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Level number (1–500)',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.boardSurface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10)),
              onPressed: _testing
                  ? null
                  : () {
                      final n = int.tryParse(_ctrl.text.trim()) ?? 1;
                      _testLevel(n);
                    },
              child: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Test',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_result != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.boardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.3)),
            ),
            child: Text(_result!,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace')),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('Copy result'),
            style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
                padding: EdgeInsets.zero),
            onPressed: _copyResult,
          ),
        ],
      ],
    );
  }
}

SolvabilityResult _check(LevelDefinition level) => checkSolvability(level);
