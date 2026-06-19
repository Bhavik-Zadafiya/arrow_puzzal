import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color boardSurface = Color(0xFF18322A);
  static const Color backgroundDark = Color(0xFF0F1F1A);
  static const Color accentGold = Color(0xFFC9A24B);
  static const Color textWarm = Color(0xFFEDE4D3);

  // Tonal variants used for scenery layers and UI depth
  static const Color surfaceLight = Color(0xFF1F3D31);   // slightly lighter than boardSurface
  static const Color surfaceDark = Color(0xFF102219);    // slightly darker than boardSurface
  static const Color statusBarBg = Color(0xFF132820);    // elevated bar tone
  static const Color goldMuted = Color(0xFF7A6130);      // muted/completed node gold
  static const Color goldCream = Color(0xFFD4B97A);      // softer completed node
  static const Color nodeLocked = Color(0xFF2A4438);     // desaturated locked node
  static const Color pathColor = Color(0xFF8A6A2E);      // winding path ribbon

  // Arrow piece direction colors
  static const Color pieceUp    = Color(0xFFC9A24B); // accentGold — warm
  static const Color pieceDown  = Color(0xFF5B9E8C); // soft teal-green
  static const Color pieceLeft  = Color(0xFFCC6B5A); // warm coral (also error flash)
  static const Color pieceRight = Color(0xFF7B9EBF); // muted steel-blue
}
