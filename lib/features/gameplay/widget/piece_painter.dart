import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/level_definition.dart';

/// [drainT] = 0 → full piece visible (resting).
/// [drainT] = 1 → piece fully off canvas.
///
/// Animation: a fixed-length window slides forward along:
///   bent corridor (inside cell)  +  straight extension (off canvas in exit dir)
///
/// The tail disappears first, the head exits last through every bend —
/// like a snake sliding out through its own curved body.
class PiecePainter extends CustomPainter {
  const PiecePainter({
    required this.cells,
    required this.direction,
    required this.isError,
    required this.cellSize,
    this.drainT = 0.0,
    this.pixelsToEdge = 0.0,
  });

  final List<GridPos> cells;
  final Direction direction;
  final bool isError;
  final double cellSize;
  final double drainT;
  /// Distance in pixels from this cell's exit edge to the grid boundary.
  /// Used so far-away pieces travel the full distance out of the canvas.
  final double pixelsToEdge;

  Color get _color => isError ? AppColors.pieceLeft : Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final sw    = math.max(4.0, cellSize * 0.22);
    final cr    = 0.0;
    final color = _color;
    final pts   = _waypoints(cells, direction, cellSize);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (drainT <= 0.0) {
      // Resting — draw full bent path + chevron.
      canvas.drawPath(_buildBentPath(pts, cr), paint);
      _drawChevron(canvas, pts.last, pts[pts.length - 2], sw, cellSize, color);
      return;
    }

    if (drainT >= 1.0) return; // fully off canvas — draw nothing.

    // Arc-length of the bent corridor (window size stays constant).
    final bentLen = _arcLength(_buildBentPath(pts, cr));

    // Total travel = piece length + distance to grid edge + a full piece-length
    // buffer so the tail also clears the grid boundary.
    final travel = bentLen + pixelsToEdge + bentLen;

    // Build the combined path with enough extension to cover the full travel.
    final extended = _buildExtendedPath(pts, cr, travel + bentLen);
    final metric   = extended.computeMetrics().first;
    final total    = metric.length;

    // Slide the fixed-length window [start, start+bentLen] along the path.
    // At drainT=0 → window at [0, bentLen]    (full piece, nothing exits).
    // At drainT=1 → window at [travel, travel+bentLen]  (fully off canvas).
    final start = drainT * travel;
    final end   = (start + bentLen).clamp(0.0, total);

    if (end > start) {
      canvas.drawPath(metric.extractPath(start, end), paint);
    }

    // Hide chevron the instant the piece starts moving.
    if (drainT < 0.08) {
      _drawChevron(
        canvas, pts.last, pts[pts.length - 2], sw, cellSize,
        color.withValues(alpha: 1.0 - drainT / 0.08),
      );
    }
  }

  // ── path builders ───────────────────────────────────────────────────────────

  /// Bent corridor only (resting shape).
  Path _buildBentPath(List<Offset> pts, double cr) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length - 1; i++) {
      _addRoundedCorner(p, pts[i - 1], pts[i], pts[i + 1], cr);
    }
    p.lineTo(pts.last.dx, pts.last.dy);
    return p;
  }

  /// Bent corridor + straight extension of [exitLen] px in the exit direction.
  Path _buildExtendedPath(List<Offset> pts, double cr, double exitLen) {
    final p = _buildBentPath(pts, cr);

    final tip  = pts.last;
    final prev = pts[pts.length - 2];
    final dx   = tip.dx - prev.dx;
    final dy   = tip.dy - prev.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > 0) {
      p.lineTo(
        tip.dx + dx / dist * exitLen,
        tip.dy + dy / dist * exitLen,
      );
    }
    return p;
  }

  static double _arcLength(Path path) =>
      path.computeMetrics().fold(0.0, (sum, m) => sum + m.length);

  // ── waypoints ───────────────────────────────────────────────────────────────

  List<Offset> _waypoints(List<GridPos> cells, Direction direction, double cellSize) {
    final pts = <Offset>[];
    for (final cell in cells) {
      final cx = (cell.col + 0.5) * cellSize;
      final cy = (cell.row + 0.5) * cellSize;
      pts.add(Offset(cx, cy));
    }

    if (pts.isNotEmpty) {
      final head = cells.last;
      final hx = (head.col + 0.5) * cellSize;
      final hy = (head.row + 0.5) * cellSize;
      final half = cellSize * 0.5;

      final edge = switch (direction) {
        Direction.right => Offset(hx + half, hy),
        Direction.left  => Offset(hx - half, hy),
        Direction.up    => Offset(hx, hy - half),
        Direction.down  => Offset(hx, hy + half),
      };
      pts.add(edge);
    }
    return pts;
  }

  void _addRoundedCorner(Path path, Offset a, Offset b, Offset c, double r) {
    final abDist = (b - a).distance;
    final bcDist = (c - b).distance;
    if (abDist == 0 || bcDist == 0) return;
    final cr = r.clamp(0.0, math.min(abDist / 2, bcDist / 2));
    if (cr < 0.5) { path.lineTo(b.dx, b.dy); return; }
    path.lineTo((b + (a - b) * (cr / abDist)).dx, (b + (a - b) * (cr / abDist)).dy);
    final p2 = b + (c - b) * (cr / bcDist);
    path.quadraticBezierTo(b.dx, b.dy, p2.dx, p2.dy);
  }

  void _drawChevron(
      Canvas canvas, Offset tip, Offset prev, double sw, double cellSize, Color color) {
    final dx = tip.dx - prev.dx, dy = tip.dy - prev.dy;
    final d = math.sqrt(dx * dx + dy * dy);
    if (d == 0) return;
    final a  = math.atan2(dy, dx);
    final al = cellSize * 0.42;
    const sp = math.pi * 0.32;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip,
        Offset(tip.dx + al * math.cos(a + math.pi - sp),
               tip.dy + al * math.sin(a + math.pi - sp)), paint);
    canvas.drawLine(tip,
        Offset(tip.dx + al * math.cos(a + math.pi + sp),
               tip.dy + al * math.sin(a + math.pi + sp)), paint);
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.direction != direction ||
      old.isError != isError ||
      old.drainT != drainT ||
      old.pixelsToEdge != pixelsToEdge ||
      old.cellSize != cellSize ||
      old.cells.length != cells.length;
}
