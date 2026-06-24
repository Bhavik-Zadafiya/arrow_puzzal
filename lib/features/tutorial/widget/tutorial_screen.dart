import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../../gameplay/data/level_service.dart';
import '../../gameplay/provider/gameplay_cubit.dart';
import '../../gameplay/provider/gameplay_state.dart';
import '../../gameplay/widget/game_grid.dart';
import '../../gameplay/widget/game_top_bar.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameplayCubit(tutorialLevel()),
      child: const _TutorialView(),
    );
  }
}

class _TutorialView extends StatefulWidget {
  const _TutorialView();

  @override
  State<_TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<_TutorialView>
    with TickerProviderStateMixin {
  // Pulsing ring animation
  late final AnimationController _pulseCtrl;
  // Ripple burst animation
  late final AnimationController _rippleCtrl;

  bool _showDone = false;
  int _tappedCount = 0;

  static const _messages = [
    'Tap the glowing arrow!',
    'Great! Keep going!',
    'You\'re getting it!',
    'One more!',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await SettingsService.instance.setTutorialSeen();
    if (mounted) context.go('/level-map');
  }

  @override
  Widget build(BuildContext context) {
    final topBarH = MediaQuery.of(context).padding.top + 62.0;

    return BlocConsumer<GameplayCubit, GameplayState>(
      listenWhen: (prev, curr) =>
          prev.pieces.length != curr.pieces.length ||
          prev.pieces.any((p) => p.hasExited) != curr.pieces.any((p) => p.hasExited),
      listener: (context, state) {
        final justExited = state.pieces.where((p) => p.hasExited).length;
        if (justExited > _tappedCount) {
          setState(() => _tappedCount = justExited);
          _rippleCtrl.forward(from: 0);
        }
        if (state.phase == GamePhase.levelComplete) {
          setState(() => _showDone = true);
        }
      },
      builder: (context, state) {
        // Find first still-active piece to highlight
        final activePieces =
            state.pieces.where((p) => p.isActive && !p.isExiting).toList();
        final hintPiece = activePieces.isNotEmpty ? activePieces.first : null;

        // Compute grid layout (mirrors GameGrid math)
        final mq = MediaQuery.of(context);
        final screenW = mq.size.width;
        final screenH = mq.size.height;
        final availH = screenH - topBarH - 32.0;
        final shorter = screenW < availH ? screenW : availH;
        final gridW = shorter * 0.88;
        final cellSize = gridW / state.level.cols;
        final gridH = cellSize * state.level.rows;
        final gridLeft = (screenW - gridW) / 2;
        final gridTop = topBarH + (availH - gridH) / 2;

        // Pixel center of the hint piece's head cell
        Offset? hintCenter;
        if (hintPiece != null && hintPiece.cells.isNotEmpty) {
          final head = hintPiece.cells.last;
          hintCenter = Offset(
            gridLeft + (head.col + 0.5) * cellSize,
            gridTop + (head.row + 0.5) * cellSize,
          );
        }

        final msgIndex = (_tappedCount).clamp(0, _messages.length - 1);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) {},
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Stack(
              children: [
                // ── Game content ─────────────────────────────────────────────
                Column(
                  children: [
                    SizedBox(height: topBarH),
                    const Expanded(child: GameGrid()),
                    const SizedBox(height: 32),
                  ],
                ),

                // ── Top bar (no close / color button needed) ────────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: GameTopBar(
                    levelId: 'Tutorial',
                    mistakes: 0,
                    maxMistakes: GameplayState.maxMistakes,
                    onClose: _finish,
                    onColorMode: () {},
                  ),
                ),

                // ── Pulsing hint ring + ripple ────────────────────────────────
                if (hintCenter != null && !_showDone)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_pulseCtrl, _rippleCtrl]),
                        builder: (_, __) => CustomPaint(
                          painter: _TutorialHintPainter(
                            center: hintCenter!,
                            pulseT: _pulseCtrl.value,
                            rippleT: _rippleCtrl.value,
                            radius: cellSize * 0.55,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Hint message bubble ───────────────────────────────────────
                if (!_showDone && hintCenter != null)
                  Positioned(
                    bottom: 110,
                    left: 32,
                    right: 32,
                    child: _MessageBubble(
                      text: _messages[msgIndex],
                      tappedCount: _tappedCount,
                      total: state.pieces.length,
                    ),
                  ),

                // ── Skip button ───────────────────────────────────────────────
                if (!_showDone)
                  Positioned(
                    bottom: 48,
                    right: 24,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip Tutorial',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textWarm.withValues(alpha: 0.40),
                        ),
                      ),
                    ),
                  ),

                // ── Done overlay ──────────────────────────────────────────────
                if (_showDone)
                  Positioned.fill(
                    child: _DoneOverlay(onContinue: _finish),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Hint painter — pulsing rings + ripple burst ───────────────────────────────

class _TutorialHintPainter extends CustomPainter {
  const _TutorialHintPainter({
    required this.center,
    required this.pulseT,
    required this.rippleT,
    required this.radius,
  });

  final Offset center;
  final double pulseT;
  final double rippleT;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = AppColors.accentGold;

    // Outer slow pulse ring
    final outerR = radius + 6 + 4 * math.sin(pulseT * math.pi);
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = gold.withValues(alpha: 0.20 + 0.10 * math.sin(pulseT * math.pi))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Inner glow fill
    canvas.drawCircle(
      center,
      radius * (0.85 + 0.12 * math.sin(pulseT * math.pi)),
      Paint()
        ..color = gold.withValues(alpha: 0.10 + 0.06 * math.sin(pulseT * math.pi))
        ..style = PaintingStyle.fill,
    );

    // Tap ripple burst (triggered on each successful tap)
    if (rippleT > 0 && rippleT < 1) {
      final t = Curves.easeOut.transform(rippleT);
      final rr = radius * (1.0 + t * 1.8);
      canvas.drawCircle(
        center,
        rr,
        Paint()
          ..color = gold.withValues(alpha: (1.0 - t) * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 3.0 * (1.0 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_TutorialHintPainter old) =>
      old.pulseT != pulseT ||
      old.rippleT != rippleT ||
      old.center != center;
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.tappedCount,
    required this.total,
  });
  final String text;
  final int tappedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWarm,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tappedCount / $total arrows cleared',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppColors.textWarm.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          // Dot indicators
          Row(
            children: List.generate(total, (i) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < tappedCount
                    ? AppColors.accentGold
                    : AppColors.textWarm.withValues(alpha: 0.15),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

// ── Done overlay ──────────────────────────────────────────────────────────────

class _DoneOverlay extends StatefulWidget {
  const _DoneOverlay({required this.onContinue});
  final VoidCallback onContinue;

  @override
  State<_DoneOverlay> createState() => _DoneOverlayState();
}

class _DoneOverlayState extends State<_DoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        color: AppColors.backgroundDark.withValues(alpha: 0.88),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFFD700), AppColors.accentGold],
                  ).createShader(b),
                  child: const Text(
                    '🎉',
                    style: TextStyle(fontSize: 64),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'You\'re Ready!',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textWarm,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap arrows to send them flying off the board.\nClear them all to win!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    color: AppColors.textWarm.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.backgroundDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "Let's Play!",
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
