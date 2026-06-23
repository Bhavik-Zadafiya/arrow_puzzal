import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class GameBottomNavBar extends StatelessWidget {
  const GameBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Iconsax.map, label: AppStrings.navMap),
    (icon: Iconsax.calendar_1, label: AppStrings.navDaily),
    (icon: Iconsax.setting_2, label: AppStrings.navSettings),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomInset,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                return _NavItem(
                  icon: _items[i].icon,
                  label: _items[i].label,
                  isActive: activeIndex == i,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget item = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 180.ms,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentGold.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isActive
              ? Border.all(color: AppColors.accentGold.withValues(alpha: 0.45), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.accentGold
                  : AppColors.textWarm.withValues(alpha: 0.45),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: isActive
                    ? AppColors.accentGold
                    : AppColors.textWarm.withValues(alpha: 0.45),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );

    if (isActive) {
      item = item
          .animate(key: ValueKey(label))
          .scaleXY(begin: 0.88, end: 1.0, duration: 200.ms, curve: Curves.easeOut);
    }

    return item;
  }
}
