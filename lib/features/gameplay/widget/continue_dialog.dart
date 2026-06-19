import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ContinueDialog extends StatelessWidget {
  const ContinueDialog({
    super.key,
    required this.lifelineCount,
    required this.onWatchAd,
    required this.onSpendLife,
    required this.onGiveUp,
  });

  final int lifelineCount;
  final VoidCallback onWatchAd;
  final VoidCallback onSpendLife;
  final VoidCallback onGiveUp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.boardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Iconsax.heart_slash,
                color: Color(0xFFE05555),
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.gameplayContinueTitle,
                style: textTheme.headlineMedium
                    ?.copyWith(color: AppColors.textWarm),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Watch ad — primary CTA
              _ActionBtn(
                label: AppStrings.gameplayWatchAd,
                icon: Iconsax.video_play,
                isPrimary: true,
                onTap: () {
                  Navigator.of(context).pop();
                  onWatchAd();
                },
              ),
              const SizedBox(height: 10),

              // Spend lifeline
              _ActionBtn(
                label:
                    '${AppStrings.gameplayUseLife}  ❤ $lifelineCount',
                icon: Iconsax.heart,
                isPrimary: false,
                enabled: lifelineCount > 0,
                onTap: lifelineCount > 0
                    ? () {
                        Navigator.of(context).pop();
                        onSpendLife();
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              // Give up — subdued
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onGiveUp();
                },
                child: Text(
                  AppStrings.gameplayGiveUp,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textWarm.withValues(alpha: 0.45),
                    decoration: TextDecoration.underline,
                    decorationColor:
                        AppColors.textWarm.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label, style: Theme.of(context).textTheme.labelLarge),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppColors.accentGold : AppColors.surfaceLight,
          foregroundColor:
              isPrimary ? AppColors.boardSurface : AppColors.textWarm,
          disabledBackgroundColor: AppColors.nodeLocked,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
