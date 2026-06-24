import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/settings_service.dart';

class ColorModeSheet extends StatefulWidget {
  const ColorModeSheet({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final PieceColorMode current;
  final void Function(PieceColorMode) onSelect;

  @override
  State<ColorModeSheet> createState() => _ColorModeSheetState();
}

class _ColorModeSheetState extends State<ColorModeSheet> {
  late PieceColorMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textWarm.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Arrow Colors',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textWarm,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how your arrows are colored',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppColors.textWarm.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 20),
          _ModeOption(
            mode: PieceColorMode.classic,
            label: 'Classic',
            subtitle: 'Clean white arrows',
            preview: _MiniArrowPreview(colors: const [
              Colors.white, Colors.white, Colors.white,
            ]),
            isSelected: _selected == PieceColorMode.classic,
            onTap: () => _pick(PieceColorMode.classic),
          ),
          const SizedBox(height: 12),
          _ModeOption(
            mode: PieceColorMode.themed,
            label: 'Themed',
            subtitle: 'Direction-based colors',
            preview: const _MiniArrowPreview(colors: [
              Color(0xFF7B9EBF), // right → steel blue
              Color(0xFFC9A24B), // up ↑ gold
              Color(0xFF5B9E8C), // down ↓ teal
            ]),
            isSelected: _selected == PieceColorMode.themed,
            onTap: () => _pick(PieceColorMode.themed),
          ),
          const SizedBox(height: 12),
          _ModeOption(
            mode: PieceColorMode.colorful,
            label: 'Colorful',
            subtitle: 'Each arrow unique',
            preview: const _MiniArrowPreview(colors: [
              Color(0xFFE8A838), // gold
              Color(0xFFD4617A), // rose
              Color(0xFF5BA8A0), // teal
            ]),
            isSelected: _selected == PieceColorMode.colorful,
            onTap: () => _pick(PieceColorMode.colorful),
          ),
        ],
      ),
    );
  }

  void _pick(PieceColorMode mode) {
    setState(() => _selected = mode);
    widget.onSelect(mode);
    Navigator.of(context).pop();
  }

}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.label,
    required this.subtitle,
    required this.preview,
    required this.isSelected,
    required this.onTap,
  });

  final PieceColorMode mode;
  final String label;
  final String subtitle;
  final Widget preview;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold.withValues(alpha: 0.10)
              : AppColors.backgroundDark.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGold.withValues(alpha: 0.70)
                : AppColors.textWarm.withValues(alpha: 0.10),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.accentGold
                          : AppColors.textWarm,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppColors.textWarm.withValues(alpha: 0.50),
                    ),
                  ),
                ],
              ),
            ),
            preview,
            const SizedBox(width: 12),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: isSelected
                  ? AppColors.accentGold
                  : AppColors.textWarm.withValues(alpha: 0.25),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini arrow canvas preview ─────────────────────────────────────────────────

class _MiniArrowPreview extends StatelessWidget {
  const _MiniArrowPreview({required this.colors});
  final List<Color> colors; // exactly 3 colors: [right, up, left]

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 36,
      child: CustomPaint(
        painter: _MiniArrowPainter(colors: colors),
      ),
    );
  }
}

class _MiniArrowPainter extends CustomPainter {
  const _MiniArrowPainter({required this.colors});
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw 3 arrows: → (right), ↑ (up), ← (left)
    // Arranged left-to-right across the canvas
    final segment = size.width / 3;
    final cy = size.height / 2;

    _arrow(canvas, Offset(segment * 0.15, cy), Offset(segment * 0.82, cy),
        colors[0]); // →

    _arrow(canvas, Offset(segment + segment * 0.5, cy + size.height * 0.38),
        Offset(segment + segment * 0.5, cy - size.height * 0.38),
        colors[1]); // ↑

    _arrow(canvas, Offset(segment * 2 + segment * 0.85, cy),
        Offset(segment * 2 + segment * 0.18, cy),
        colors[2]); // ←
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    final ux = dx / len, uy = dy / len;
    final sw = 2.2;
    final headLen = len * 0.42;
    final headWid = len * 0.22;

    // Body: from tail to slightly before tip
    final bodyEnd = Offset(to.dx - ux * headLen, to.dy - uy * headLen);
    canvas.drawLine(
      from,
      bodyEnd,
      Paint()
        ..color = color
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head: filled triangle
    final px = -uy, py = ux; // perpendicular
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(bodyEnd.dx + px * headWid, bodyEnd.dy + py * headWid)
      ..lineTo(bodyEnd.dx - px * headWid, bodyEnd.dy - py * headWid)
      ..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_MiniArrowPainter old) => old.colors != colors;
}
