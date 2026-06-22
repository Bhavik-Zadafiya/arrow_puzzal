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
          // Fill available space while keeping the grid square.
          final shorter =
              constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight;
          final gridW = shorter * 0.88;
          final cellSize = gridW / state.level.cols;
          final gridH = cellSize * state.level.rows;

          return Center(
            child: SizedBox(
              width: gridW,
              height: gridH,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final x = details.localPosition.dx;
                  final y = details.localPosition.dy;
                  final col = (x / cellSize).floor().clamp(0, state.level.cols - 1);
                  final row = (y / cellSize).floor().clamp(0, state.level.rows - 1);

                  final piece = state.pieceAt(row, col);
                  if (piece != null) {
                    context.read<GameplayCubit>().tapPiece(piece.id);
                  }
                },
                child: Stack(
                  // pieces animate out of bounds — allow overflow
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(
                          rows: state.level.rows,
                          cols: state.level.cols,
                        ),
                      ),
                    ),
                    ...state.pieces.where((p) => !p.hasExited).map((piece) {
                      return Positioned(
                        key: ValueKey(piece.id),
                        left: 0,
                        top: 0,
                        width: gridW,
                        height: gridH,
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

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.rows, required this.cols});
  final int rows;
  final int cols;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );

    // Background
    canvas.drawRRect(rr, Paint()..color = AppColors.boardSurface);

    // 2500 small dots — one per cell centre
    final dotPaint = Paint()
      ..color = AppColors.textWarm.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    const dotR = 1.4;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
          Offset((c + 0.5) * cellW, (r + 0.5) * cellH),
          dotR,
          dotPaint,
        );
      }
    }

    // Border glow
    canvas.drawRRect(
      rr,
      Paint()
        ..color = AppColors.accentGold.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.rows != rows || old.cols != cols;
}
