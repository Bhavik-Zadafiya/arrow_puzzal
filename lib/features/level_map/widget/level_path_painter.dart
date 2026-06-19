import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Draws only the winding path ribbon connecting level nodes.
/// Background scenery is now handled by real image assets in the parent Stack.
class LevelPathPainter extends CustomPainter {
  const LevelPathPainter({required this.nodePositions});

  final List<Offset> nodePositions;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;
    _drawShadow(canvas);
    _drawRibbon(canvas);
    _drawEdgeHighlight(canvas);
  }

  void _drawShadow(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_buildPath(), paint);
  }

  void _drawRibbon(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_buildPath(), paint);
  }

  void _drawEdgeHighlight(Canvas canvas) {
    // Thin bright line along the top edge of the ribbon for depth
    final paint = Paint()
      ..color = AppColors.goldCream.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_buildPath(), paint);
  }

  Path _buildPath() {
    final path = Path();
    path.moveTo(nodePositions.first.dx, nodePositions.first.dy);

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final p0 = nodePositions[i];
      final p1 = nodePositions[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      path.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(LevelPathPainter old) => old.nodePositions != nodePositions;
}
