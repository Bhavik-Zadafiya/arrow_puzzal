import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentGold,
          surface: AppColors.boardSurface,
          onPrimary: AppColors.backgroundDark,
          onSurface: AppColors.textWarm,
        ),
        textTheme: AppTextStyles.textTheme,
        useMaterial3: true,
      );
}
