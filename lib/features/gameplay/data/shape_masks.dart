import 'dart:math' as math;

enum ShapeType {
  heart, star, circle, diamond, cross, hexagon,
  arrow, moon, lightning, tree, fish, boat, house, bell,
}

/// Returns the set of 'row,col' keys inside [shape] for a [rows]×[cols] grid.
Set<String> buildShapeMask(ShapeType shape, int rows, int cols) {
  return switch (shape) {
    ShapeType.heart     => _heart(rows, cols),
    ShapeType.star      => _star(rows, cols),
    ShapeType.circle    => _circle(rows, cols),
    ShapeType.diamond   => _diamond(rows, cols),
    ShapeType.cross     => _cross(rows, cols),
    ShapeType.hexagon   => _hexagon(rows, cols),
    ShapeType.arrow     => _arrow(rows, cols),
    ShapeType.moon      => _moon(rows, cols),
    ShapeType.lightning => _lightning(rows, cols),
    ShapeType.tree      => _tree(rows, cols),
    ShapeType.fish      => _fish(rows, cols),
    ShapeType.boat      => _boat(rows, cols),
    ShapeType.house     => _house(rows, cols),
    ShapeType.bell      => _bell(rows, cols),
  };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Ray-casting point-in-polygon. Vertices as list of (x, y) in any coord space.
bool _pip(double x, double y, List<(double, double)> poly) {
  bool inside = false;
  final n = poly.length;
  int j = n - 1;
  for (int i = 0; i < n; i++) {
    final (xi, yi) = poly[i];
    final (xj, yj) = poly[j];
    if (((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

/// Scan all cells; add those where [test] returns true.
Set<String> _scan(
    int rows, int cols, bool Function(double x, double y) test) {
  final mask = <String>{};
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      // Centred coords: x ∈ (−1, 1), y ∈ (−1, 1), y increases downward.
      final x = ((c + 0.5) / cols) * 2.0 - 1.0;
      final y = ((r + 0.5) / rows) * 2.0 - 1.0;
      if (test(x, y)) mask.add('$r,$c');
    }
  }
  return mask;
}

// ── 1. Heart ──────────────────────────────────────────────────────────────────
// (x²+y²−1)³ − x²y³ ≤ 0   (standard heart, tip points down)

Set<String> _heart(int rows, int cols) => _scan(rows, cols, (x, y) {
      final sx = x * 1.2, sy = -y * 1.1 - 0.1; // flip so tip is at bottom
      final s = sx * sx + sy * sy - 1.0;
      return s * s * s - sx * sx * sy * sy * sy <= 0.0;
    });

// ── 2. Star (5-pointed) ───────────────────────────────────────────────────────

Set<String> _star(int rows, int cols) {
  final cx = (cols - 1) / 2.0, cy = (rows - 1) / 2.0;
  final R = math.min(cx, cy) * 0.96, r = R * 0.42;
  return _scan(rows, cols, (x, y) {
    final dx = x * cx, dy = y * cy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return true;
    if (dist > R * 1.01) return false;
    double angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;
    final t = (angle / (math.pi / 5)) % 2.0;
    final starR = t <= 1.0 ? R - (R - r) * t : r + (R - r) * (t - 1.0);
    return dist <= starR;
  });
}

// ── 3. Circle ─────────────────────────────────────────────────────────────────

Set<String> _circle(int rows, int cols) =>
    _scan(rows, cols, (x, y) => x * x + y * y <= 0.92);

// ── 4. Diamond ────────────────────────────────────────────────────────────────

Set<String> _diamond(int rows, int cols) =>
    _scan(rows, cols, (x, y) => x.abs() + y.abs() <= 0.95);

// ── 5. Cross / Plus ───────────────────────────────────────────────────────────

Set<String> _cross(int rows, int cols) =>
    _scan(rows, cols, (x, y) => x.abs() <= 0.30 || y.abs() <= 0.30);

// ── 6. Hexagon ────────────────────────────────────────────────────────────────

Set<String> _hexagon(int rows, int cols) {
  final sq3 = math.sqrt(3);
  return _scan(rows, cols, (x, y) {
    final ax = x.abs(), ay = y.abs();
    return ax <= 0.94 && ay <= 0.94 * sq3 / 2 &&
        ax + ay * sq3 / 3 <= 0.94 * 4 / 3;
  });
}

// ── 7. Arrow (right-pointing ➡) ───────────────────────────────────────────────

Set<String> _arrow(int rows, int cols) {
  const shaft = [
    (-1.0, -0.28), (0.10, -0.28),
    (0.10,  0.28), (-1.0,  0.28),
  ];
  const head = [
    (0.10, -0.80), (1.00,  0.00), (0.10,  0.80),
  ];
  return _scan(rows, cols,
      (x, y) => _pip(x, y, shaft) || _pip(x, y, head));
}

// ── 8. Moon (crescent 🌙) ─────────────────────────────────────────────────────

Set<String> _moon(int rows, int cols) => _scan(rows, cols, (x, y) {
      final inOuter = x * x + y * y <= 0.90;
      final bx = x + 0.38, by = y;
      final inBite = bx * bx + by * by <= 0.62;
      return inOuter && !inBite;
    });

// ── 9. Lightning bolt (⚡) ────────────────────────────────────────────────────

Set<String> _lightning(int rows, int cols) {
  // Two parallelograms forming the classic bolt
  const top = [
    (0.05, -0.95), (0.60, -0.95),
    (0.00,  0.05), (-0.55, 0.05),
  ];
  const bottom = [
    (-0.05, -0.05), (0.50, -0.05),
    (-0.05,  0.95), (-0.60, 0.95),
  ];
  return _scan(rows, cols,
      (x, y) => _pip(x, y, top) || _pip(x, y, bottom));
}

// ── 10. Pine tree (🌲) ────────────────────────────────────────────────────────

Set<String> _tree(int rows, int cols) {
  // Three stacked triangles (top to bottom) + narrow trunk
  bool inTriangle(double x, double y, double top, double bot, double wScale) {
    if (y < top || y > bot) return false;
    final t = (y - top) / (bot - top); // 0 at apex, 1 at base
    return x.abs() <= t * wScale;
  }
  return _scan(rows, cols, (x, y) {
    final inTop    = inTriangle(x, y, -0.95, -0.35, 0.45);
    final inMid    = inTriangle(x, y, -0.60, 0.15, 0.65);
    final inBottom = inTriangle(x, y, -0.15, 0.65, 0.85);
    final inTrunk  = x.abs() <= 0.12 && y >= 0.60 && y <= 0.95;
    return inTop || inMid || inBottom || inTrunk;
  });
}

// ── 11. Fish (🐟) ─────────────────────────────────────────────────────────────

Set<String> _fish(int rows, int cols) => _scan(rows, cols, (x, y) {
      // Elliptical body (shifted right)
      final bx = (x - 0.12) / 0.68, by = y / 0.50;
      final inBody = bx * bx + by * by <= 1.0;
      // Triangular tail on the left
      final tx = x + 0.82; // distance from tail tip
      final inTail = x >= -1.0 && x <= -0.40 &&
          y.abs() <= tx / 0.42 * 0.55;
      return inBody || inTail;
    });

// ── 12. Boat (⛵) ─────────────────────────────────────────────────────────────

Set<String> _boat(int rows, int cols) => _scan(rows, cols, (x, y) {
      // Hull: trapezoid at bottom third
      final hy = 0.32;
      final inHull = y >= hy && y <= 0.90 &&
          x.abs() <= 0.85 - (y - hy) / (0.90 - hy) * 0.25;
      // Mast: thin vertical from deck to top
      final inMast = x.abs() <= 0.05 && y >= -0.85 && y <= hy + 0.02;
      // Sail: right triangle (left side of mast to top-right)
      final inSail = x >= 0.05 && y >= -0.82 && y <= hy &&
          x <= 0.80 * (y - hy) / (-0.82 - hy) + 0.05;
      return inHull || inMast || inSail;
    });

// ── 13. House (🏠) ────────────────────────────────────────────────────────────

Set<String> _house(int rows, int cols) {
  // Roof: isoceles triangle
  const roof = [(-0.90, 0.05), (0.0, -0.90), (0.90, 0.05)];
  return _scan(rows, cols, (x, y) {
    final inWalls = x.abs() <= 0.78 && y >= 0.05 && y <= 0.90;
    final inRoof  = _pip(x, y, roof);
    // Door: small rectangle at bottom center
    final inDoor  = x.abs() <= 0.18 && y >= 0.48 && y <= 0.90;
    return inWalls || inRoof || inDoor;
  });
}

// ── 14. Bell (🔔) ─────────────────────────────────────────────────────────────

Set<String> _bell(int rows, int cols) => _scan(rows, cols, (x, y) {
      // Dome: upper semicircle (squashed ellipse)
      final inDome = y <= 0.35 &&
          (x / 0.82) * (x / 0.82) + ((y + 0.45) / 0.90) * ((y + 0.45) / 0.90) <=
              1.0;
      // Skirt: expanding trapezoid at bottom
      final inSkirt = y >= 0.25 && y <= 0.70 &&
          x.abs() <= 0.55 + (y - 0.25) / 0.45 * 0.30;
      // Clapper: small circle below
      final inClapper = x * x + ((y - 0.82) / 0.14) * ((y - 0.82) / 0.14) <= 1.0;
      return inDome || inSkirt || inClapper;
    });
