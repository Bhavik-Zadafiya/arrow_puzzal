import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../data/level_definition.dart';
import '../data/solvability.dart';

/// Tests solvability of [level] and shows a detailed result.
/// Only visible in debug builds (kDebugMode).
class DevTestDialog extends StatefulWidget {
  const DevTestDialog({super.key, required this.level});
  final LevelDefinition level;

  @override
  State<DevTestDialog> createState() => _DevTestDialogState();
}

class _DevTestDialogState extends State<DevTestDialog> {
  SolvabilityResult? _result;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _copyReport(BuildContext ctx, SolvabilityResult r) {
    final text = _buildReport(widget.level, r);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF2A5C45),
      ),
    );
  }

  Future<void> _run() async {
    setState(() { _running = true; _result = null; });
    final result = await compute(_check, widget.level);
    if (!mounted) return;
    setState(() { _running = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final ok = r != null && r.isSolvable && !r.hasOverlaps && r.isFullCoverage;

    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          children: [
            // ── Title bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.boardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dev Test — Level ${widget.level.id}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (r != null)
                    Icon(ok ? Icons.check_circle : Icons.cancel,
                        color: ok ? Colors.greenAccent : Colors.redAccent, size: 20),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: _running
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFFFD700)),
                          SizedBox(height: 12),
                          Text('Running solvability test…',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ))
                  : r == null
                      ? const SizedBox()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _ResultBody(result: r),
                        ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Re-run'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFD700)),
                    onPressed: _run,
                  ),
                  const SizedBox(width: 8),
                  if (r != null)
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      onPressed: () => _copyReport(context, r),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.boardSurface,
                      foregroundColor: Colors.white,
                    ),
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
}

SolvabilityResult _check(LevelDefinition level) => checkSolvability(level);

String _buildReport(LevelDefinition level, SolvabilityResult r) {
  final buf = StringBuffer();
  buf.writeln('=== Dev Test Report — Level ${level.id} ===');
  buf.writeln('Grid     : ${level.rows}×${level.cols}');
  buf.writeln('Pieces   : ${r.totalPieces}');
  buf.writeln('Coverage : ${r.totalCells}/${r.expectedCells}');
  buf.writeln('Overlaps : ${r.hasOverlaps ? r.overlaps.length : "None"}');
  buf.writeln('Solvable : ${r.isSolvable ? "YES (${r.rounds} rounds)" : "NO"}');
  if (r.hasOverlaps) {
    buf.writeln('\n--- Overlaps ---');
    for (final o in r.overlaps) { buf.writeln(o); }
  }
  if (!r.isSolvable) {
    buf.writeln('\n--- Stuck pieces ---');
    buf.writeln(r.stuckPieces.join(', '));
  }
  buf.writeln('\n--- Round log ---');
  for (final line in r.roundLog) { buf.writeln(line); }
  return buf.toString();
}

// ── Result body ──────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});
  final SolvabilityResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stat('Pieces', '${r.totalPieces}'),
        _stat('Grid cells', '${r.totalCells} / ${r.expectedCells}'),
        _stat('Overlaps', r.hasOverlaps ? '${r.overlaps.length} ⚠' : 'None ✓',
            bad: r.hasOverlaps),
        _stat('Coverage', r.isFullCoverage ? 'Full ✓' : '${r.totalCells}/${r.expectedCells} ⚠',
            bad: !r.isFullCoverage),
        _stat('Solvable', r.isSolvable ? 'Yes ✓ (${r.rounds} rounds)' : 'NO ✗',
            bad: !r.isSolvable),
        const SizedBox(height: 12),
        if (r.hasOverlaps) ...[
          _sectionTitle('Overlapping cells', Colors.redAccent),
          for (final line in r.overlaps.take(6))
            _line(line, Colors.redAccent),
          const SizedBox(height: 8),
        ],
        if (!r.isSolvable) ...[
          _sectionTitle('Stuck pieces (${r.stuckPieces.length})', Colors.redAccent),
          _line(r.stuckPieces.take(12).join(', '), Colors.redAccent),
          const SizedBox(height: 8),
        ],
        if (r.isSolvable) ...[
          _sectionTitle('Round log', Colors.white54),
          for (final line in r.roundLog)
            _line(line, Colors.white54),
        ],
      ],
    );
  }

  Widget _stat(String label, String value, {bool bad = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(value,
                style: TextStyle(
                    color: bad ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _sectionTitle(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      );

  Widget _line(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text('  $text',
            style: TextStyle(color: color, fontSize: 11)),
      );
}
