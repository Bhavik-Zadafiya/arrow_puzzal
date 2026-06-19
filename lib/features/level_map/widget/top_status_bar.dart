import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class TopStatusBar extends StatelessWidget implements PreferredSizeWidget {
  const TopStatusBar({
    super.key,
    required this.lifelineCount,
    required this.lifelineMax,
    required this.regenSecondsRemaining,
  });

  final int lifelineCount;
  final int lifelineMax;
  final int regenSecondsRemaining;

  static const double _barHeight = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    final topPad  = MediaQuery.of(context).padding.top;
    final isFull  = lifelineCount >= lifelineMax;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _barHeight + topPad,
          padding: EdgeInsets.only(top: topPad, left: 12, right: 12),
          decoration: BoxDecoration(
            // Frosted glass — same family as the floating bottom nav
            color: AppColors.backgroundDark.withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(
                color: AppColors.accentGold.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: lives pill ──────────────────────────────────────
              _LivesPill(count: lifelineCount, max: lifelineMax),
              const SizedBox(width: 6),

              // ── Regen timer (only when not full) ─────────────────────
              if (!isFull)
                _RegenBadge(secondsRemaining: regenSecondsRemaining)
                    .animate()
                    .fadeIn(duration: 400.ms),

              // ── Centre: app name (flexible so it never overflows) ─────
              Expanded(
                child: Center(child: _AppTitle()),
              ),

              // ── Right: profile button only ────────────────────────────
              _ProfileButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lives pill  ❤ 7/10
// ─────────────────────────────────────────────────────────────────────────────

class _LivesPill extends StatelessWidget {
  const _LivesPill({required this.count, required this.max});
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final pct = count / max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.12),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing heart icon
          const Icon(Iconsax.heart, color: Color(0xFFE05555), size: 16)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.18, duration: 900.ms, curve: Curves.easeInOut),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Count text
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textWarm,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '/$max',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textWarm.withValues(alpha: 0.45),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              // Mini progress bar
              SizedBox(
                width: 36,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.textWarm.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE05555)),
                    minHeight: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regen timer badge  ⟳ 14m 00s
// ─────────────────────────────────────────────────────────────────────────────

class _RegenBadge extends StatelessWidget {
  const _RegenBadge({required this.secondsRemaining});
  final int secondsRemaining;

  String get _label {
    final m = secondsRemaining ~/ 60;
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (secondsRemaining / 1800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.boardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textWarm.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: AppColors.textWarm.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textWarm.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App title — centre anchor
// ─────────────────────────────────────────────────────────────────────────────

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFD4B97A), AppColors.accentGold, Color(0xFFF0D080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Text(
        AppStrings.appName,
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white, // masked by gradient shader
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// _CoinBadge removed — will be re-added once currency system is built

// ─────────────────────────────────────────────────────────────────────────────
// Profile button
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.boardSurface,
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Iconsax.profile_circle,
          color: AppColors.textWarm,
          size: 18,
        ),
      ),
    );
  }
}
