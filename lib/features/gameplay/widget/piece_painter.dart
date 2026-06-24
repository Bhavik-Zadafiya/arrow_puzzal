import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/level_definition.dart';

/// Paints one piece as a connected bent corridor plus a solid filled
/// arrowhead at the exit end.
///
/// The path body ends at the HEAD CELL CENTRE so the arrowhead (tip at the
/// cell boundary) visually "sticks out" like  ━━━► rather than ━━━►(buried).
///
/// [drainT] = 0 → full piece; 1 → fully off canvas (exit animation).
class PiecePainter extends CustomPainter {
  const PiecePainter({
    required this.cells,
    required this.direction,
    required this.isError,
    required this.isHinted,
    required this.cellSize,
    this.drainT = 0.0,
    this.pixelsToEdge = 0.0,
  });

  final List<GridPos> cells;
  final Direction direction;
  final bool isError;
  final bool isHinted;
  final double cellSize;
  final double drainT;
  final double pixelsToEdge;

  Color get _color {
    if (isError) return AppColors.pieceLeft;
    if (isHinted) return const Color(0xFFFFD700);
    return Colors.white;
  }

  // Arrowhead is always gold so it pops out even when bodies of adjacent
  // pieces are touching. Error state keeps red for the whole piece.
  Color get _tipColor {
    if (isError) return AppColors.pieceLeft;
    if (isHinted) return const Color(0xFFFFD700);
    return AppColors.accentGold;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sw    = (cellSize * 0.28).clamp(2.5, 5.0);
    final color = _color;
    final pts   = _waypoints(cells, direction, cellSize);
    if (pts.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (drainT <= 0.0) {
      // Resting: body up to head-cell centre + arrowhead tip at cell edge.
      final body = _buildBodyPath(pts);
      // For 1-cell pieces, add a stub tail in the opposite direction so the
      // piece looks like ─► rather than just ►.
      if (cells.length == 1) {
        final center = pts[pts.length - 2];
        final edge   = pts.last;
        final stubEnd = Offset(
          center.dx + (center.dx - edge.dx) * 0.45,
          center.dy + (center.dy - edge.dy) * 0.45,
        );
        body.moveTo(center.dx, center.dy);
        body.lineTo(stubEnd.dx, stubEnd.dy);
      }
      canvas.drawPath(body, paint);
      _drawArrowHead(canvas, pts.last, pts[pts.length - 2], cellSize, _tipColor,
          numCells: cells.length);
      return;
    }

    if (drainT >= 1.0) return;

    // ── Exit animation ──────────────────────────────────────────────────────
    // Arc-length of the full body (tail → head cell centre).
    final bodyLen = _arcLength(_buildBodyPath(pts));

    // Total travel: body + exit gap + a full body-length buffer.
    final travel = bodyLen + pixelsToEdge + bodyLen;

    // Extended path: body + straight extension out the exit side.
    final extended = _buildExtendedPath(pts, travel + bodyLen);
    final metric   = extended.computeMetrics().first;
    final total    = metric.length;

    final start = drainT * travel;
    final end   = (start + bodyLen).clamp(0.0, total);

    if (end > start) {
      canvas.drawPath(metric.extractPath(start, end), paint);
    }

    // Arrowhead fades out at the very start of the animation.
    if (drainT < 0.08) {
      _drawArrowHead(
        canvas, pts.last, pts[pts.length - 2], cellSize,
        color.withValues(alpha: 1.0 - drainT / 0.08),
        numCells: cells.length,
      );
    }
  }

  // ── Path builders ──────────────────────────────────────────────────────────

  /// Bent corridor from tail → head cell CENTRE (pts[last-1]).
  /// The edge waypoint (pts.last) is NOT included so the arrowhead protrudes.
  Path _buildBodyPath(List<Offset> pts) {
    // pts: [...body cells..., headCellCentre, edgePoint]
    // Body ends at pts[pts.length - 2] = headCellCentre.
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    final bodyEnd = pts.length - 2; // index of head cell centre

    for (int i = 1; i < bodyEnd; i++) {
      _addRoundedCorner(p, pts[i - 1], pts[i], pts[i + 1]);
    }
    p.lineTo(pts[bodyEnd].dx, pts[bodyEnd].dy);
    return p;
  }

  /// Body + straight extension past the edge for the drain animation.
  Path _buildExtendedPath(List<Offset> pts, double exitLen) {
    final p = _buildBodyPath(pts); // ends at head cell centre

    // Continue from head-cell centre through the edge and beyond.
    final centre = pts[pts.length - 2];
    final edge   = pts.last;
    final dx = edge.dx - centre.dx;
    final dy = edge.dy - centre.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > 0) {
      p.lineTo(
        centre.dx + dx / dist * (dist + exitLen),
        centre.dy + dy / dist * (dist + exitLen),
      );
    }
    return p;
  }

  static double _arcLength(Path path) =>
      path.computeMetrics().fold(0.0, (sum, m) => sum + m.length);

  // ── Waypoints ──────────────────────────────────────────────────────────────

  List<Offset> _waypoints(
      List<GridPos> cells, Direction direction, double cellSize) {
    final pts = <Offset>[];
    for (final cell in cells) {
      pts.add(Offset((cell.col + 0.5) * cellSize, (cell.row + 0.5) * cellSize));
    }
    if (pts.isNotEmpty) {
      final head = cells.last;
      final hx   = (head.col + 0.5) * cellSize;
      final hy   = (head.row + 0.5) * cellSize;
      final half = cellSize * 0.5;

      final edgePt = switch (direction) {
        Direction.right => Offset(hx + half, hy),
        Direction.left  => Offset(hx - half, hy),
        Direction.up    => Offset(hx, hy - half),
        Direction.down  => Offset(hx, hy + half),
      };

      // If the natural exit of the body disagrees with [direction] (can happen
      // when the cycle-breaker forced a non-natural direction), insert a short
      // redirect waypoint 20 % into the last cell toward [direction].
      // This makes the body visually turn before the arrowhead so the tip
      // always matches the actual exit direction.
      if (cells.length >= 2) {
        final p = cells[cells.length - 2];
        final h = cells.last;
        final naturalDir = (h.col > p.col) ? Direction.right
            : (h.col < p.col) ? Direction.left
            : (h.row > p.row) ? Direction.down
            : Direction.up;

        if (naturalDir != direction) {
          final offset = cellSize * 0.20;
          final redirect = switch (direction) {
            Direction.right => Offset(hx + offset, hy),
            Direction.left  => Offset(hx - offset, hy),
            Direction.up    => Offset(hx, hy - offset),
            Direction.down  => Offset(hx, hy + offset),
          };
          pts.add(redirect);
        }
      }

      pts.add(edgePt);
    }
    return pts;
  }

  // ── Corner rounding ────────────────────────────────────────────────────────

  void _addRoundedCorner(Path path, Offset a, Offset b, Offset c) {
    const r = 0.0; // sharp corners — set > 0 for rounded bends
    final abDist = (b - a).distance;
    final bcDist = (c - b).distance;
    if (abDist == 0 || bcDist == 0) return;
    if (r < 0.5) {
      path.lineTo(b.dx, b.dy);
      return;
    }
    final cr = r.clamp(0.0, math.min(abDist / 2, bcDist / 2));
    final p1 = b + (a - b) * (cr / abDist);
    final p2 = b + (c - b) * (cr / bcDist);
    path.lineTo(p1.dx, p1.dy);
    path.quadraticBezierTo(b.dx, b.dy, p2.dx, p2.dy);
  }

  // ── Arrowhead ──────────────────────────────────────────────────────────────

  /// Solid filled triangle. Tip at [tip] (cell edge), base centred on [prev]
  /// (head cell centre) — so the arrowhead visually protrudes past the body.
  /// [numCells] is used to scale the arrowhead narrower on very short pieces.
  void _drawArrowHead(
      Canvas canvas, Offset tip, Offset prev, double cellSize, Color color,
      {int numCells = 10}) {
    final dx = tip.dx - prev.dx, dy = tip.dy - prev.dy;
    final d = math.sqrt(dx * dx + dy * dy);
    if (d == 0) return;

    final ux = dx / d, uy = dy / d; // unit forward
    final px = -uy, py =  ux;       // unit perpendicular

    // Arrowhead spans the full half-cell (centre → edge).
    final len = d;                    // = cellSize * 0.5
    // Scale base width down for very short pieces so the head looks proportional
    // to the (short) body rather than dominating it.
    final wid = numCells >= 4
        ? cellSize * 0.36
        : numCells == 3
            ? cellSize * 0.30
            : numCells == 2
                ? cellSize * 0.22
                : cellSize * 0.16;

    // Base is at [prev] (head cell centre).
    final bx = tip.dx - ux * len;
    final by = tip.dy - uy * len;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(bx + px * wid, by + py * wid)
      ..lineTo(bx - px * wid, by - py * wid)
      ..close();

    // Filled body.
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.fill);

    // Thin stroke outline so it reads clearly on any background.
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.direction != direction ||
      old.isError != isError ||
      old.isHinted != isHinted ||
      old.drainT != drainT ||
      old.pixelsToEdge != pixelsToEdge ||
      old.cellSize != cellSize ||
      old.cells.length != cells.length;
}
