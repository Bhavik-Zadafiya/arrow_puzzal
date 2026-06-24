import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/daily_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/settings_service.dart';
import '../data/level_definition.dart';
import '../provider/gameplay_cubit.dart';
import '../provider/gameplay_state.dart';
import 'color_mode_sheet.dart';
import 'continue_dialog.dart';
import 'dev_test_dialog.dart';
import 'game_grid.dart';
import 'game_top_bar.dart';
import 'level_complete_overlay.dart';

class GameplayScreen extends StatelessWidget {
  const GameplayScreen({
    super.key,
    required this.levelNumber,
    required this.level,
    this.isDaily = false,
  });

  final int levelNumber;
  final LevelDefinition level;
  /// True when this is the daily challenge puzzle.
  final bool isDaily;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameplayCubit(level),
      child: _GameplayView(
          levelNumber: levelNumber, level: level, isDaily: isDaily),
    );
  }
}

class _GameplayView extends StatelessWidget {
  const _GameplayView({
    required this.levelNumber,
    required this.level,
    required this.isDaily,
  });
  final int levelNumber;
  final LevelDefinition level;
  final bool isDaily;

  int _starsFromMistakes(int mistakes) {
    if (mistakes == 0) return 3;
    if (mistakes == 1) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameplayCubit, GameplayState>(
      listenWhen: (prev, curr) => prev.phase != curr.phase,
      listener: (context, state) {
        if (state.phase == GamePhase.levelComplete) {
          final stars = _starsFromMistakes(state.mistakes);
          if (isDaily) {
            DailyService.instance.completeToday(stars);
          } else {
            ProgressService.instance.completeLevel(levelNumber, stars);
          }
          // Success pulse: two heavy bumps
          if (SettingsService.instance.hapticsEnabled) {
            HapticFeedback.heavyImpact();
            Future.delayed(const Duration(milliseconds: 120),
                HapticFeedback.heavyImpact);
          }
        }

        if (state.phase == GamePhase.failed) {
          // Failure pattern: rapid triple buzz
          if (SettingsService.instance.hapticsEnabled) {
            HapticFeedback.vibrate();
            Future.delayed(const Duration(milliseconds: 100),
                HapticFeedback.vibrate);
            Future.delayed(const Duration(milliseconds: 200),
                HapticFeedback.vibrate);
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => ContinueDialog(
              lifelineCount: state.lifelineCount,
              onWatchAd: () => context.read<GameplayCubit>().watchAd(),
              onSpendLife: () => context.read<GameplayCubit>().spendLifeline(),
              onGiveUp: () => context.pop(),
            ),
          );
        }
      },
      builder: (context, state) {
        final topBarHeight = MediaQuery.of(context).padding.top + 62.0;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmLeave(context);
            if (leave && context.mounted) context.pop();
          },
          child: Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Stack(
            children: [
              // Game content — pushed down so the grid clears the top bar.
              Column(
                children: [
                  SizedBox(height: topBarHeight),
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      // Allow panning only when zoomed in (clip prevents overflow)
                      clipBehavior: Clip.none,
                      child: const GameGrid(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),

              // Level complete overlay
              if (state.phase == GamePhase.levelComplete)
                Positioned.fill(
                  child: LevelCompleteOverlay(
                    mistakes: state.mistakes,
                    isDaily: isDaily,
                    onNext: () {
                      if (isDaily) {
                        context.pop(); // back to level-map
                      } else if (levelNumber < 500) {
                        context.pushReplacement(
                            '/gameplay?level=${levelNumber + 1}');
                      } else {
                        context.pop();
                      }
                    },
                    onHome: () => context.pop(),
                  ),
                ),

              // ── Top bar — rendered LAST so it always sits above animated pieces ──
              Positioned(
                top: 0, left: 0, right: 0,
                child: GameTopBar(
                  levelId: state.level.id,
                  mistakes: state.mistakes,
                  maxMistakes: GameplayState.maxMistakes,
                  onClose: () async {
                    final leave = await _confirmLeave(context);
                    if (leave && context.mounted) context.pop();
                  },
                  onColorMode: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ColorModeSheet(
                      current: SettingsService.instance.pieceColorMode,
                      onSelect: (mode) async {
                        await SettingsService.instance.setPieceColorMode(mode);
                        // Force grid rebuild by triggering a state update
                        if (context.mounted) {
                          context.read<GameplayCubit>().refreshColors();
                        }
                      },
                    ),
                  ),
                ),
              ),

              // ── Floating hint button (bottom center) ─────────────────────
              if (state.phase == GamePhase.playing)
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _HintFab(
                      hintsRemaining: state.hintsRemaining,
                      isActive: state.pieces.any((p) => p.isHinted),
                      onTap: () async {
                        final cubit = context.read<GameplayCubit>();
                        if (SettingsService.instance.hapticsEnabled) {
                          HapticFeedback.selectionClick();
                        }
                        if (state.pieces.any((p) => p.isHinted)) {
                          cubit.clearHint();
                          return;
                        }
                        final result = await cubit.requestHint();
                        if (!context.mounted) return;
                        if (result == HintResult.noMovesAvailable) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No moves available right now!'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF7B3F00),
                            ),
                          );
                        } else if (result == HintResult.exhausted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => _HintAdDialog(
                              onWatchAd: () {
                                context.read<GameplayCubit>().watchHintAd();
                                Navigator.of(ctx).pop();
                              },
                              onCancel: () => Navigator.of(ctx).pop(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),

              // ── Developer buttons (debug builds only) ────────────────────
              if (kDebugMode)
                Positioned(
                  bottom: 40,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // SOLVE button
                      GestureDetector(
                        onTap: () => context.read<GameplayCubit>().autoSolve(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.7)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Color(0xFF00E676), size: 14),
                              SizedBox(width: 4),
                              Text('SOLVE',
                                  style: TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // DEV TEST button
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => DevTestDialog(level: level),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bug_report,
                                  color: Color(0xFFFFD700), size: 14),
                              SizedBox(width: 4),
                              Text('DEV TEST',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),  // Scaffold
        );  // PopScope
      },
    );
  }
}

// ── Shared leave-game confirmation ────────────────────────────────────────────

Future<bool> _confirmLeave(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ConfirmDialog(
      title: 'Leave Level?',
      message: 'Your progress in this level will be lost.',
      confirmLabel: 'Leave',
      cancelLabel: 'Keep Playing',
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.boardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.exit_to_app_rounded,
                color: AppColors.accentGold, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textWarm,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppColors.textWarm.withValues(alpha: 0.60),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textWarm,
                      side: BorderSide(
                          color: AppColors.textWarm.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(cancelLabel,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB03030),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating hint FAB ─────────────────────────────────────────────────────────

class _HintFab extends StatefulWidget {
  const _HintFab({
    required this.hintsRemaining,
    required this.isActive,
    required this.onTap,
  });
  final int hintsRemaining;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_HintFab> createState() => _HintFabState();
}

class _HintFabState extends State<_HintFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_HintFab old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _ctrl.repeat(reverse: true);
    if (!widget.isActive && old.isActive) { _ctrl.stop(); _ctrl.value = 0; }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.hintsRemaining <= 0;
    final active  = widget.isActive;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -5 * _ctrl.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                    : AppColors.boardSurface,
                border: Border.all(
                  color: isEmpty
                      ? AppColors.textWarm.withValues(alpha: 0.15)
                      : active
                          ? const Color(0xFFFFD700)
                          : AppColors.accentGold.withValues(alpha: 0.50),
                  width: active ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (active
                            ? const Color(0xFFFFD700)
                            : AppColors.accentGold)
                        .withValues(alpha: active ? 0.35 : 0.12),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: isEmpty
                    ? AppColors.textWarm.withValues(alpha: 0.30)
                    : active
                        ? const Color(0xFFFFD700)
                        : AppColors.textWarm,
                size: 24,
              ),
            ),
            // Count badge
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? AppColors.textWarm.withValues(alpha: 0.20)
                      : AppColors.accentGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.hintsRemaining}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isEmpty
                        ? AppColors.textWarm.withValues(alpha: 0.40)
                        : AppColors.backgroundDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hint exhausted dialog ─────────────────────────────────────────────────────

class _HintAdDialog extends StatelessWidget {
  const _HintAdDialog({required this.onWatchAd, required this.onCancel});
  final VoidCallback onWatchAd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.boardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.accentGold, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No Hints Left Today',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textWarm,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve used all 3 free hints for today.\nWatch a short ad to get 3 more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppColors.textWarm.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onWatchAd,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text('Watch Ad (+3 Hints)',
                    style: TextStyle(fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onCancel,
              child: Text('Maybe Later',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: AppColors.textWarm.withValues(alpha: 0.45),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
