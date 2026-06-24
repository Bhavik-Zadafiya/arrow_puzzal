import 'package:flutter/material.dart' show Color, Colors;
import 'package:shared_preferences/shared_preferences.dart';

enum PieceColorMode { classic, themed, colorful }

/// Per-piece color given a mode, piece index, and direction.
/// Classic  = white.
/// Themed   = direction-based (matches AppColors).
/// Colorful = vibrant rotating palette regardless of direction.
Color pieceColorFor(PieceColorMode mode, int pieceIndex, dynamic direction) {
  switch (mode) {
    case PieceColorMode.classic:
      return Colors.white;
    case PieceColorMode.themed:
      // direction is Direction enum — match by name
      final name = direction.toString();
      if (name.contains('right')) return const Color(0xFF7B9EBF);
      if (name.contains('left'))  return const Color(0xFFCC6B5A);
      if (name.contains('up'))    return const Color(0xFFC9A24B);
      return const Color(0xFF5B9E8C);
    case PieceColorMode.colorful:
      const palette = [
        Color(0xFFE8A838), // gold
        Color(0xFF5BA8A0), // teal
        Color(0xFFD4617A), // rose
        Color(0xFF7B9EBF), // steel blue
        Color(0xFF8EC97A), // green
        Color(0xFFB97BD4), // purple
        Color(0xFFE8784A), // orange
        Color(0xFF5BACD4), // sky blue
        Color(0xFFD4A55B), // amber
        Color(0xFF7AD4B2), // mint
      ];
      return palette[pieceIndex % palette.length];
  }
}

/// Lightweight singleton for misc user preferences.
/// Call [init] once at app startup after WidgetsFlutterBinding.ensureInitialized().
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Haptics ────────────────────────────────────────────────────────────────

  bool get hapticsEnabled => _prefs.getBool('haptics_enabled') ?? true;

  Future<void> setHapticsEnabled(bool v) =>
      _prefs.setBool('haptics_enabled', v);

  // ── Difficulty (1–10) ─────────────────────────────────────────────────────
  //
  // 1 = easiest, 5 = default, 10 = intense.
  // Stored as int so it survives restarts.

  int get difficultyLevel => (_prefs.getInt('difficulty_level') ?? 1).clamp(1, 10);

  Future<void> setDifficultyLevel(int v) =>
      _prefs.setInt('difficulty_level', v.clamp(1, 10));

  // ── Tutorial ───────────────────────────────────────────────────────────────

  bool get tutorialSeen => _prefs.getBool('tutorial_seen') ?? false;

  Future<void> setTutorialSeen() => _prefs.setBool('tutorial_seen', true);

  // ── Piece color mode ───────────────────────────────────────────────────────

  PieceColorMode get pieceColorMode {
    final i = _prefs.getInt('piece_color_mode') ?? 0;
    return PieceColorMode.values[i.clamp(0, PieceColorMode.values.length - 1)];
  }

  Future<void> setPieceColorMode(PieceColorMode m) =>
      _prefs.setInt('piece_color_mode', m.index);
}
