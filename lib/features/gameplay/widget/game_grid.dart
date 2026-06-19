import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../provider/gameplay_cubit.dart';
import '../provider/gameplay_state.dart';
import 'piece_widget.dart';

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameplayCubit, GameplayState>(
      builder: (context, state) {
        return LayoutBuilder(builder: (context, constraints) {
          // Fill available space while keeping the grid square (for 5×5).
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
                      left: piece.col * cellSize,
                      top: piece.row * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: PieceWidget(
                        key: ValueKey(piece.id),
                        piece: piece,
                        cellSize: cellSize,
                        onTap: () =>
                            context.read<GameplayCubit>().tapPiece(piece.id),
                        onExitComplete: () =>
                            context.read<GameplayCubit>().pieceExited(piece.id),
                      ),
                    );
                  }),
                ],
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

    // Inner cell lines
    final linePaint = Paint()
      ..color = AppColors.textWarm.withValues(alpha: 0.07)
      ..strokeWidth = 1;

    for (int r = 1; r < rows; r++) {
      canvas.drawLine(
          Offset(0, r * cellH), Offset(size.width, r * cellH), linePaint);
    }
    for (int c = 1; c < cols; c++) {
      canvas.drawLine(
          Offset(c * cellW, 0), Offset(c * cellW, size.height), linePaint);
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
