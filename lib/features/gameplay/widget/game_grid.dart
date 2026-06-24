import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../data/level_definition.dart';
import '../provider/gameplay_cubit.dart';
import '../provider/gameplay_state.dart';
import 'piece_widget.dart';

double _pixelsToEdge(GamePiece piece, int rows, int cols, double cellSize) {
  if (piece.cells.isEmpty) return 0.0;
  final head = piece.cells.last;
  return switch (piece.direction) {
    Direction.right => (cols - 1 - head.col) * cellSize,
    Direction.left  => head.col * cellSize,
    Direction.up    => head.row * cellSize,
    Direction.down  => (rows - 1 - head.row) * cellSize,
  };
}

class GameGrid extends StatefulWidget {
  const GameGrid({super.key});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _rippleCtrl;
  Offset? _ripplePos;
  Color _rippleColor = AppColors.accentGold;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _triggerRipple(Offset pos, Color color) {
    setState(() {
      _ripplePos = pos;
      _rippleColor = color;
    });
    _rippleCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameplayCubit, GameplayState>(
      builder: (context, state) {
        return LayoutBuilder(builder: (context, constraints) {
          final shorter = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;
          final gridW    = shorter * 0.88;
          final cellSize = gridW / state.level.cols;
          final gridH    = cellSize * state.level.rows;

          return Center(
            child: SizedBox(
              width: gridW,
              height: gridH,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final x   = details.localPosition.dx;
                  final y   = details.localPosition.dy;
                  final col = (x / cellSize).floor().clamp(0, state.level.cols - 1);
                  final row = (y / cellSize).floor().clamp(0, state.level.rows - 1);
                  final piece = state.pieceAt(row, col);
                  if (piece != null) {
                    if (SettingsService.instance.hapticsEnabled) {
                      HapticFeedback.selectionClick();
                    }
                    // Determine the piece's color for the ripple tint
                    final idx = state.pieces.indexOf(piece);
                    final color = pieceColorFor(
                      SettingsService.instance.pieceColorMode, idx, piece.direction);
                    // Ripple at cell centre
                    final center = Offset(
                      (col + 0.5) * cellSize,
                      (row + 0.5) * cellSize,
                    );
                    _triggerRipple(center, color);
                    context.read<GameplayCubit>().tapPiece(piece.id);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(
                          rows:       state.level.rows,
                          cols:       state.level.cols,
                          shapeCells: state.level.shapeCells,
                        ),
                      ),
                    ),
                    ...state.pieces.asMap().entries
                        .where((e) => !e.value.hasExited)
                        .map((entry) {
                      final piece = entry.value;
                      final colorMode = SettingsService.instance.pieceColorMode;
                      final pieceColor = pieceColorFor(colorMode, entry.key, piece.direction);
                      return Positioned(
                        key: ValueKey(piece.id),
                        left: 0, top: 0,
                        width: gridW, height: gridH,
                        child: IgnorePointer(
                          child: PieceWidget(
                            piece: piece,
                            cellSize: cellSize,
                            gridWidth: gridW,
                            gridHeight: gridH,
                            pixelsToEdge: _pixelsToEdge(
                              piece,
                              state.level.rows,
                              state.level.cols,
                              cellSize,
                            ),
                            onTap: () {},
                            onExitComplete: () =>
                                context.read<GameplayCubit>().pieceExited(piece.id),
                            pieceColor: pieceColor,
                          ),
                        ),
                      );
                    }),

                    // ── Tap ripple overlay ───────────────────────────────────
                    if (_ripplePos != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _rippleCtrl,
                            builder: (_, __) {
                              return CustomPaint(
                                painter: _RipplePainter(
                                  center: _ripplePos!,
                                  progress: _rippleCtrl.value,
                                  maxRadius: cellSize * 0.72,
                                  color: _rippleColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

// ── Ripple painter ────────────────────────────────────────────────────────────

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.center,
    required this.progress,
    required this.maxRadius,
    required this.color,
  });

  final Offset center;
  final double progress;
  final double maxRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Ease-out curve for natural feel
    final t = Curves.easeOut.transform(progress);
    final radius = maxRadius * t;
    // Fade: full opacity at start, gone by end
    final alpha  = (1.0 - t).clamp(0.0, 1.0);

    // Outer expanding ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, 2.5 * (1.0 - t)),
    );

    // Inner fill flash (only first 30 % of animation)
    if (t < 0.30) {
      final innerAlpha = (1.0 - t / 0.30).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        radius * 0.45,
        Paint()
          ..color = color.withValues(alpha: innerAlpha * 0.18)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.center != center || old.color != color;
}

// ── Grid painter ──────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.rows,
    required this.cols,
    this.shapeCells,
  });
  final int rows;
  final int cols;
  final Set<String>? shapeCells;

  @override
  void paint(Canvas canvas, Size size) {
    if (shapeCells == null) {
      _paintRect(canvas, size);
    } else {
      _paintShape(canvas, size);
    }
  }

  // ── Standard rectangular grid ─────────────────────────────────────────────

  void _paintRect(Canvas canvas, Size size) {
    final cw = size.width  / cols;
    final ch = size.height / rows;
    final rr = RRect.fromRectAndRadius(
      Offset.zero & size, const Radius.circular(18));

    canvas.drawRRect(rr, Paint()..color = AppColors.boardSurface);

    final dotPaint = Paint()
      ..color = AppColors.textWarm.withValues(alpha: 0.18);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
            Offset((c + 0.5) * cw, (r + 0.5) * ch), 1.4, dotPaint);
      }
    }

    canvas.drawRRect(rr, Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  // ── Shaped grid ───────────────────────────────────────────────────────────

  void _paintShape(Canvas canvas, Size size) {
    final shape = shapeCells!;
    final cw = size.width  / cols;
    final ch = size.height / rows;
    const gap = 1.2;
    const r   = 3.0;

    final cellPaint = Paint()..color = AppColors.boardSurface;
    final dotPaint  = Paint()
      ..color = AppColors.textWarm.withValues(alpha: 0.20);
    final edgePaint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final edgeCells = <String>{};

    for (final key in shape) {
      final parts = key.split(',');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(col * cw + gap, row * ch + gap,
            cw - gap * 2, ch - gap * 2),
        Radius.circular(r),
      );
      canvas.drawRRect(rect, cellPaint);

      canvas.drawCircle(
          Offset((col + 0.5) * cw, (row + 0.5) * ch), 1.4, dotPaint);

      final neighbours = [
        '${row - 1},$col', '${row + 1},$col',
        '$row,${col - 1}', '$row,${col + 1}',
      ];
      if (neighbours.any((n) => !shape.contains(n))) {
        edgeCells.add(key);
      }
    }

    for (final key in edgeCells) {
      final parts = key.split(',');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final left   = col * cw + gap;
      final top    = row * ch + gap;
      final right  = (col + 1) * cw - gap;
      final bottom = (row + 1) * ch - gap;

      if (!shape.contains('${row - 1},$col')) {
        canvas.drawLine(Offset(left, top), Offset(right, top), edgePaint);
      }
      if (!shape.contains('${row + 1},$col')) {
        canvas.drawLine(Offset(left, bottom), Offset(right, bottom), edgePaint);
      }
      if (!shape.contains('$row,${col - 1}')) {
        canvas.drawLine(Offset(left, top), Offset(left, bottom), edgePaint);
      }
      if (!shape.contains('$row,${col + 1}')) {
        canvas.drawLine(Offset(right, top), Offset(right, bottom), edgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.rows != rows || old.cols != cols || old.shapeCells != shapeCells;
}
