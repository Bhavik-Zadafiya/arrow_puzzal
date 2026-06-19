import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class LevelCompleteOverlay extends StatelessWidget {
  const LevelCompleteOverlay({
    super.key,
    required this.mistakes,
    required this.onNext,
    required this.onHome,
  });

  final int mistakes;
  final VoidCallback onNext;
  final VoidCallback onHome;

  int get _stars {
    if (mistakes == 0) return 3;
    if (mistakes == 1) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.backgroundDark.withValues(alpha: 0.93),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < _stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    filled ? Iconsax.star_1 : Iconsax.star,
                    size: 52,
                    color: filled
                        ? AppColors.accentGold
                        : AppColors.textWarm.withValues(alpha: 0.18),
                  )
                      .animate(delay: (i * 200).ms)
                      .scale(
                        begin: const Offset(0.1, 0.1),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 250.ms),
                );
              }),
            ),
            const SizedBox(height: 28),

            Text(
              AppStrings.gameplayLevelComplete,
              style: textTheme.displayLarge?.copyWith(
                color: AppColors.textWarm,
                fontSize: 32,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 400.ms)
                .moveY(begin: 18, end: 0, duration: 400.ms),

            const SizedBox(height: 44),

            SizedBox(
              width: 220,
              height: 54,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.boardSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  AppStrings.gameplayNextLevel,
                  style: textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            )
                .animate(delay: 900.ms)
                .fadeIn(duration: 300.ms)
                .moveY(begin: 14, end: 0, duration: 300.ms),

            const SizedBox(height: 14),

            TextButton(
              onPressed: onHome,
              child: Text(
                AppStrings.gameplayBackToMap,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textWarm.withValues(alpha: 0.45),
                ),
              ),
            ).animate(delay: 1000.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
