/// All user-facing strings live here — no exceptions.
///
/// Convention for future features:
///   static const String levelCompleteTitle = 'Level complete';
///   static const String levelCompleteSubtitle = 'Nice work!';
///
/// Group strings by feature with a comment header, e.g.:
///   // --- Level Map ---
///   static const String levelMapTitle = 'Choose a level';
///
/// Never place a raw string literal for displayed text in any widget.
class AppStrings {
  AppStrings._();

  // --- App ---
  static const String appName = 'Arrow Pussal';

  // --- Splash ---
  static const String splashTagline = 'A calm puzzle escape';

  // --- Level Map ---
  static const String navMap = 'Map';
  static const String navDaily = 'Daily';
  static const String navSettings = 'Settings';
  static const String lifelineLabel = 'Lives';
  static const String lifelineRegenLabel = 'Full in';
  static const String levelLocked = 'Locked';
  static const String levelCurrent = 'Play';
  static const String levelMilestone = 'Milestone';
  static const String dailyPlaceholder = 'Daily challenges coming soon';
  static const String settingsPlaceholder = 'Settings coming soon';

  // --- Gameplay ---
  static const String gameplayLevelLabel    = 'Level';
  static const String gameplayContinueTitle = 'Out of moves!';
  static const String gameplayWatchAd       = 'Watch Ad';
  static const String gameplayUseLife       = 'Use a Life';
  static const String gameplayGiveUp        = 'Give Up';
  static const String gameplayLevelComplete = 'Puzzle Solved!';
  static const String gameplayNextLevel     = 'Next Level';
  static const String gameplayBackToMap     = 'Back to Map';
}
