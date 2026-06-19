import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.levelId,
    required this.mistakes,
    required this.maxMistakes,
    required this.onClose,
  });

  final String levelId;
  final int mistakes;
  final int maxMistakes;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
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
              // Back button
              _CircleBtn(icon: Iconsax.arrow_left, onTap: onClose),
              const SizedBox(width: 14),

              // Level label
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.goldCream, AppColors.accentGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(b),
                child: Text(
                  '${AppStrings.gameplayLevelLabel} $levelId',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),

              const Spacer(),

              // Mistake hearts — right to left: filled = remaining, hollow = used
              Row(
                children: List.generate(maxMistakes, (i) {
                  final isUsed = i < mistakes;
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
