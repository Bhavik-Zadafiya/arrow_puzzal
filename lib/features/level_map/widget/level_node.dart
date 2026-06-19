import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../provider/level_map_state.dart';

class LevelNode extends StatelessWidget {
  const LevelNode({super.key, required this.level, this.onTap});

  final LevelData level;
  final VoidCallback? onTap;

  static const double _normalSize  = 56;
  static const double _milestoneSize = 72;

  @override
  Widget build(BuildContext context) {
    final size = level.isMilestone ? _milestoneSize : _normalSize;

    Widget node = GestureDetector(
      onTap: level.status != LevelStatus.locked ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCircle(size, Theme.of(context).textTheme),
          if (level.status == LevelStatus.completed && !level.isMilestone)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _StarRating(stars: level.stars),
            ),
        ],
      ),
    );

    // Pulse glow on the "play next" node
    if (level.status == LevelStatus.current) {
      node = node
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.06, duration: 900.ms, curve: Curves.easeInOut);
    }

    return node;
  }

  Widget _buildCircle(double size, TextTheme textTheme) {
    if (level.isMilestone) {
      return _MilestoneCircle(level: level, size: size, textTheme: textTheme);
    }
    if (level.status == LevelStatus.current) {
      return _CurrentCircle(level: level, size: size, textTheme: textTheme);
    }
    return _PlainCircle(level: level, size: size, textTheme: textTheme);
  }
}

// ---------------------------------------------------------------------------

class _MilestoneCircle extends StatelessWidget {
  const _MilestoneCircle({required this.level, required this.size, required this.textTheme});
  final LevelData level;
  final double size;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    // Ring image already contains its own dark centre — just overlay the number
    final ringSize = size * 1.55;
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(AppAssets.milestoneRing, width: ringSize, height: ringSize),
          Text(
            '${level.id}',
            style: textTheme.headlineMedium?.copyWith(
              fontSize: size * 0.34,
              color: AppColors.accentGold,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.05, duration: 1800.ms, curve: Curves.easeInOut);
  }
}

// ---------------------------------------------------------------------------

class _CurrentCircle extends StatelessWidget {
  const _CurrentCircle({required this.level, required this.size, required this.textTheme});
  final LevelData level;
  final double size;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final orbSize = size * 1.5;
    return SizedBox(
      width: orbSize,
      height: orbSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arrow orb glow behind
          Opacity(
            opacity: 0.65,
            child: Image.asset(AppAssets.arrowOrb, width: orbSize, height: orbSize),
          ),
          // Gold circle with level number on top
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.55),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${level.id}',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: size * 0.32,
                  color: AppColors.boardSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PlainCircle extends StatelessWidget {
  const _PlainCircle({required this.level, required this.size, required this.textTheme});
  final LevelData level;
  final double size;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final isCompleted = level.status == LevelStatus.completed;
    final isLocked    = level.status == LevelStatus.locked;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Locked nodes use a medium-grey-green so they read clearly against bg
        color: isLocked
            ? const Color(0xFF3D5A4C)
            : AppColors.goldMuted,
        border: Border.all(
          color: isLocked
              ? AppColors.textWarm.withValues(alpha: 0.25)
              : AppColors.goldCream,
          width: isLocked ? 1.5 : 2,
        ),
        boxShadow: isCompleted
            ? [BoxShadow(color: AppColors.accentGold.withValues(alpha: 0.2), blurRadius: 8)]
            : isLocked
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6)]
                : null,
      ),
      child: Center(
        child: isLocked
            ? Icon(
                Iconsax.lock,
                // White-ish so the padlock is clearly legible on the grey-green bg
                color: AppColors.textWarm.withValues(alpha: 0.70),
                size: size * 0.40,
              )
            : Text(
                '${level.id}',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: size * 0.32,
                  color: AppColors.goldCream,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StarRating extends StatelessWidget {
  const _StarRating({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Icon(
        i < stars ? Iconsax.star_1 : Iconsax.star,
        size: 10,
        color: i < stars
            ? AppColors.accentGold
            : AppColors.textWarm.withValues(alpha: 0.22),
      )),
    );
  }
}
