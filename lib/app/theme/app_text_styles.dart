import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display / heading — Baloo 2: rounded, bold, playful (level numbers, splash title, big UI moments)
  static TextStyle get display => GoogleFonts.baloo2(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.textWarm,
        letterSpacing: 0.5,
      );

  static TextStyle get headlineLarge => GoogleFonts.baloo2(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textWarm,
      );

  static TextStyle get headlineMedium => GoogleFonts.baloo2(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textWarm,
      );

  // Body / UI — Nunito: clean, rounded-readable (buttons, labels, settings, smaller text)
  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textWarm,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textWarm,
      );

  static TextStyle get labelLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textWarm,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textWarm.withValues(alpha: 0.7),
      );

  /// Build a [TextTheme] wiring both fonts into the app theme.
  /// Feature code should pull styles from [Theme.of(context).textTheme],
  /// never by calling GoogleFonts.xxx() directly.
  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
        bodySmall: caption,
      );
}
