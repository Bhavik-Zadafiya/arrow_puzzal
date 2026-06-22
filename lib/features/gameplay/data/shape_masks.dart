import 'dart:math' as math;

enum ShapeType { heart, star, circle, diamond, cross, hexagon }

/// Returns the set of 'row,col' keys that are INSIDE the given shape,
/// for a grid of [rows] × [cols] cells.
Set<String> buildShapeMask(ShapeType shape, int rows, int cols) {
  return switch (shape) {
    ShapeType.heart   => _heart(rows, cols),
    ShapeType.star    => _star(rows, cols),
    ShapeType.circle  => _circle(rows, cols),
    ShapeType.diamond => _diamond(rows, cols),
    ShapeType.cross   => _cross(rows, cols),
    ShapeType.hexagon => _hexagon(rows, cols),
  };
}

// ── Heart ─────────────────────────────────────────────────────────────────────
// Formula: (x²+y²−1)³ − x²y³ ≤ 0
// x ∈ [−1.2, 1.2]  col →  right
// y ∈ [−1.1, 1.1]  row ↓  (flipped so top of grid = top of heart)

Set<String> _heart(int rows, int cols) {
  final mask = <String>{};
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final x =  ((c + 0.5) / cols) * 2.4 - 1.2;
      final y = -((r + 0.5) / rows) * 2.2 + 1.1;
      final s = x * x + y * y - 1.0;
      if (s * s * s - x * x * y * y * y <= 0.0) {
        mask.add('$r,$c');
      }
    }
  }
  return mask;
}

// ── 5-pointed Star ────────────────────────────────────────────────────────────

Set<String> _star(int rows, int cols) {
  final mask = <String>{};
  final cx = (cols - 1) / 2.0;
  final cy = (rows - 1) / 2.0;
  final outerR = math.min(cx, cy) * 0.96;
  final innerR = outerR * 0.42; // classic 5-star proportion

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (_inStar(c - cx, r - cy, 5, outerR, innerR)) {
        mask.add('$r,$c');
      }
    }
  }
  return mask;
}

bool _inStar(double x, double y, int n, double outerR, double innerR) {
  final dist = math.sqrt(x * x + y * y);
  if (dist == 0) return true;
  if (dist > outerR * 1.01) return false;
  // Angle from top, clockwise
  double angle = math.atan2(x, -y);
  if (angle < 0) angle += 2 * math.pi;
  final sectorAngle = math.pi / n; // half-angle between adjacent outer points
  final t = (angle / sectorAngle) % 2.0;
  final starR = t <= 1.0
      ? outerR - (outerR - innerR) * t
      : innerR + (outerR - innerR) * (t - 1.0);
  return dist <= starR;
}

// ── Circle ────────────────────────────────────────────────────────────────────

Set<String> _circle(int rows, int cols) {
  final mask = <String>{};
  final cx = (cols - 1) / 2.0;
  final cy = (rows - 1) / 2.0;
  final rx = cols / 2.0 - 0.5;
  final ry = rows / 2.0 - 0.5;
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final dx = (c - cx) / rx;
      final dy = (r - cy) / ry;
      if (dx * dx + dy * dy <= 1.0) {
        mask.add('$r,$c');
      }
    }
  }
  return mask;
}

// ── Diamond ───────────────────────────────────────────────────────────────────

Set<String> _diamond(int rows, int cols) {
  final mask = <String>{};
  final cx = (cols - 1) / 2.0;
  final cy = (rows - 1) / 2.0;
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final dx = (c - cx) / (cols / 2.0);
      final dy = (r - cy) / (rows / 2.0);
      if (dx.abs() + dy.abs() <= 1.0) {
        mask.add('$r,$c');
      }
    }
  }
  return mask;
}

// ── Cross / Plus ──────────────────────────────────────────────────────────────

Set<String> _cross(int rows, int cols) {
  final mask = <String>{};
  final cx = (cols - 1) / 2.0;
  final cy = (rows - 1) / 2.0;
  final armW = cols * 0.28; // arm half-width ≈ 28 % of grid
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final dx = (c - cx).abs();
      final dy = (r - cy).abs();
      if (dx <= armW || dy <= armW) {
        mask.add('$r,$c');
      }
    }
  }
  return mask;
}

// ── Hexagon ───────────────────────────────────────────────────────────────────

Set<String> _hexagon(int rows, int cols) {
  final mask = <String>{};
  final cx = (cols - 1) / 2.0;
  final cy = (rows - 1) / 2.0;
  final R  = math.min(cx, cy) * 0.97;
  final sq3 = math.sqrt(3);

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final x = (c - cx).abs();
      final y = (r - cy).abs();
      // Flat-top hexagon: width = R, height = R*√3/2
      if (x <= R && y <= R * sq3 / 2 && x + y * sq3 / 3 <= R * 4 / 3) {
        mask.add('$r,$c');
      }
    }
  }
  return mask;
}
