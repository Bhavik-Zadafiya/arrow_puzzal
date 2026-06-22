import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
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

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});

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
                    ...state.pieces.where((p) => !p.hasExited).map((piece) {
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
                          ),
                        ),
                      );
                    }),
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
    const gap = 1.2; // px gap between adjacent cells
    const r   = 3.0; // cell corner radius

    final cellPaint = Paint()..color = AppColors.boardSurface;
    final dotPaint  = Paint()
      ..color = AppColors.textWarm.withValues(alpha: 0.20);
    final edgePaint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Collect edge cells (cells in shape that have at least one neighbour NOT in shape)
    final edgeCells = <String>{};

    for (final key in shape) {
      final parts = key.split(',');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);

      // Draw filled cell
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(col * cw + gap, row * ch + gap,
            cw - gap * 2, ch - gap * 2),
        Radius.circular(r),
      );
      canvas.drawRRect(rect, cellPaint);

      // Dot at centre
      canvas.drawCircle(
          Offset((col + 0.5) * cw, (row + 0.5) * ch), 1.4, dotPaint);

      // Check if edge cell
      final neighbours = [
        '${row - 1},$col', '${row + 1},$col',
        '$row,${col - 1}', '$row,${col + 1}',
      ];
      if (neighbours.any((n) => !shape.contains(n))) {
        edgeCells.add(key);
      }
    }

    // Draw gold border on exposed edges of edge cells
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
