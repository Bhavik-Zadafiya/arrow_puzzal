import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/level_definition.dart';

/// Thin white corridor segment with 4 bends, snaking across the full cell.
/// Exit direction is confirmed by a chevron arrowhead at the terminal point.
/// Error state flashes coral-red for the shake animation.
class PiecePainter extends CustomPainter {
  const PiecePainter({required this.direction, required this.isError});

  final Direction direction;
  final bool isError;

  static const double _strokeFrac = 0.065; // thin line — matches reference style
  static const double _cornerFrac = 0.05;  // tight crisp right-angle corner

  Color get _color => isError ? AppColors.pieceLeft : Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final s     = math.min(size.width, size.height);
    final sw    = s * _strokeFrac;
    final cr    = s * _cornerFrac;
    final inset = sw * 0.5; // cap sits flush with cell edge
    final color = _color;
    final pts   = _waypoints(s, inset);

    canvas.drawPath(
      _buildPath(pts, cr),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _drawChevron(canvas, pts.last, pts[pts.length - 2], sw, color);
  }

  /// Six waypoints → four 90° bends → path snakes across most of the cell.
  ///
  ///  RIGHT: left-edge → right → down → left → down → right-edge
  ///  LEFT:  right-edge → left → down → right → down → left-edge
  ///  UP:    bottom-edge → up → right → down → right → top-edge
  ///  DOWN:  top-edge → down → right → up → right → bottom-edge
  List<Offset> _waypoints(double s, double inset) {
    return switch (direction) {
      Direction.right => [
        Offset(inset,       s * 0.20), // start — left edge
        Offset(s * 0.80,    s * 0.20), // → right across top
        Offset(s * 0.80,    s * 0.50), // ↓ down to middle
        Offset(s * 0.20,    s * 0.50), // ← left across middle
        Offset(s * 0.20,    s * 0.80), // ↓ down to bottom row
        Offset(s - inset,   s * 0.80), // → exit right
      ],
      Direction.left => [
        Offset(s - inset,   s * 0.20), // start — right edge
        Offset(s * 0.20,    s * 0.20), // ← left across top
        Offset(s * 0.20,    s * 0.50), // ↓ down to middle
        Offset(s * 0.80,    s * 0.50), // → right across middle
        Offset(s * 0.80,    s * 0.80), // ↓ down to bottom row
        Offset(inset,       s * 0.80), // ← exit left
      ],
      Direction.up => [
        Offset(s * 0.20,    s - inset), // start — bottom edge
        Offset(s * 0.20,    s * 0.20),  // ↑ up along left column
        Offset(s * 0.50,    s * 0.20),  // → right across top
        Offset(s * 0.50,    s * 0.80),  // ↓ down to bottom area
        Offset(s * 0.80,    s * 0.80),  // → right along bottom
        Offset(s * 0.80,    inset),     // ↑ exit top
      ],
      Direction.down => [
        Offset(s * 0.20,    inset),     // start — top edge
        Offset(s * 0.20,    s * 0.80),  // ↓ down along left column
        Offset(s * 0.50,    s * 0.80),  // → right across bottom
        Offset(s * 0.50,    s * 0.20),  // ↑ up to top area
        Offset(s * 0.80,    s * 0.20),  // → right along top
        Offset(s * 0.80,    s - inset), // ↓ exit bottom
      ],
    };
  }

  Path _buildPath(List<Offset> pts, double cr) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length - 1; i++) {
      _addRoundedCorner(path, pts[i - 1], pts[i], pts[i + 1], cr);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  void _addRoundedCorner(Path path, Offset a, Offset b, Offset c, double r) {
    final abDist = (b - a).distance;
    final bcDist = (c - b).distance;
    if (abDist == 0 || bcDist == 0) return;

    final clampR = r.clamp(0.0, math.min(abDist / 2, bcDist / 2));
    final p1 = b + (a - b) * (clampR / abDist);
    final p2 = b + (c - b) * (clampR / bcDist);

    path.lineTo(p1.dx, p1.dy);
    path.quadraticBezierTo(b.dx, b.dy, p2.dx, p2.dy);
  }

  void _drawChevron(
      Canvas canvas, Offset tip, Offset prev, double sw, Color color) {
    final dx   = tip.dx - prev.dx;
    final dy   = tip.dy - prev.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final angle  = math.atan2(dy, dx);
    final armLen = sw * 2.6; // proportionally visible against thin stroke
    const spread = math.pi * 0.36;

    final p1 = Offset(
      tip.dx + armLen * math.cos(angle + math.pi - spread),
      tip.dy + armLen * math.sin(angle + math.pi - spread),
    );
    final p2 = Offset(
      tip.dx + armLen * math.cos(angle + math.pi + spread),
      tip.dy + armLen * math.sin(angle + math.pi + spread),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.85
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(tip, p1, paint);
    canvas.drawLine(tip, p2, paint);
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.direction != direction || old.isError != isError;
}
