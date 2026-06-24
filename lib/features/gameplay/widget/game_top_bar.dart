import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class GameTopBar extends StatefulWidget {
  const GameTopBar({
    super.key,
    required this.levelId,
    required this.mistakes,
    required this.maxMistakes,
    required this.onClose,
    required this.onHint,
    this.isHintActive = false,
    this.hintsRemaining = 3,
  });

  final String levelId;
  final int mistakes;
  final int maxMistakes;
  final VoidCallback onClose;
  final VoidCallback onHint;
  final bool isHintActive;
  final int hintsRemaining;

  @override
  State<GameTopBar> createState() => _GameTopBarState();
}

class _GameTopBarState extends State<GameTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _jumpCtrl;

  @override
  void initState() {
    super.initState();
    _jumpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    if (widget.isHintActive) _jumpCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GameTopBar old) {
    super.didUpdateWidget(old);
    if (widget.isHintActive && !old.isHintActive) {
      _jumpCtrl.repeat(reverse: true);
    }
    if (!widget.isHintActive && old.isHintActive) {
      _jumpCtrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _jumpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad   = MediaQuery.of(context).padding.top;
    final textTheme = Theme.of(context).textTheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(
                color: AppColors.accentGold.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _CircleBtn(icon: Iconsax.arrow_left, onTap: widget.onClose),
              const SizedBox(width: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.goldCream, AppColors.accentGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(b),
                    child: Text(
                      '${AppStrings.gameplayLevelLabel} ${widget.levelId}',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Hint bulb button ──────────────────────────────────────────
              AnimatedBuilder(
                animation: _jumpCtrl,
                builder: (_, child) => Transform.translate(
                  // jump up to -6 px then back
                  offset: Offset(0, -6 * _jumpCtrl.value),
                  child: child,
                ),
                child: GestureDetector(
                  onTap: widget.onHint,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isHintActive
                              ? const Color(0xFFFFD700).withValues(alpha: 0.22)
                              : AppColors.boardSurface,
                          border: Border.all(
                            color: widget.hintsRemaining <= 0
                                ? AppColors.textWarm.withValues(alpha: 0.15)
                                : widget.isHintActive
                                    ? const Color(0xFFFFD700)
                                    : AppColors.accentGold.withValues(alpha: 0.30),
                            width: widget.isHintActive ? 1.8 : 1.0,
                          ),
                        ),
                        child: Icon(
                          Iconsax.lamp_on,
                          color: widget.hintsRemaining <= 0
                              ? AppColors.textWarm.withValues(alpha: 0.30)
                              : widget.isHintActive
                                  ? const Color(0xFFFFD700)
                                  : AppColors.textWarm,
                          size: 18,
                        ),
                      ),
                      // Hint count badge (top-right of button)
                      Positioned(
                        top: -4,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: widget.hintsRemaining <= 0
                                ? AppColors.textWarm.withValues(alpha: 0.20)
                                : AppColors.accentGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.hintsRemaining}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: widget.hintsRemaining <= 0
                                  ? AppColors.textWarm.withValues(alpha: 0.40)
                                  : AppColors.backgroundDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Mistake hearts ─────────────────────────────────────────────
              Row(
                children: List.generate(widget.maxMistakes, (i) {
                  final isUsed = i < widget.mistakes;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      isUsed ? Iconsax.heart_slash : Iconsax.heart,
                      color: isUsed
                          ? AppColors.textWarm.withValues(alpha: 0.22)
                          : const Color(0xFFE05555),
                      size: 24,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.boardSurface,
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppColors.textWarm, size: 18),
      ),
    );
  }
}
