import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/daily_service.dart';
import '../../../core/services/progress_service.dart';
import '../data/level_definition.dart';
import '../provider/gameplay_cubit.dart';
import '../provider/gameplay_state.dart';
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
        }

        if (state.phase == GamePhase.failed) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => ContinueDialog(
              lifelineCount: state.mockLifelines,
              onWatchAd: () => context.read<GameplayCubit>().watchAd(),
              onSpendLife: () => context.read<GameplayCubit>().spendLifeline(),
              onGiveUp: () => context.go('/level-map'),
            ),
          );
        }
      },
      builder: (context, state) {
        final topBarHeight = MediaQuery.of(context).padding.top + 62.0;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Stack(
            children: [
              // Game content — pushed down so the grid clears the top bar.
              Column(
                children: [
                  SizedBox(height: topBarHeight),
                  const Expanded(child: GameGrid()),
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
                        context.go('/level-map');
                      } else if (levelNumber < 500) {
                        context.go('/gameplay?level=${levelNumber + 1}');
                      } else {
                        context.go('/level-map');
                      }
                    },
                    onHome: () => context.go('/level-map'),
                  ),
                ),

              // ── Top bar — rendered LAST so it always sits above animated pieces ──
              Positioned(
                top: 0, left: 0, right: 0,
                child: GameTopBar(
                  levelId: state.level.id,
                  complexity: state.level.complexity,
                  mistakes: state.mistakes,
                  maxMistakes: GameplayState.maxMistakes,
                  onClose: () => context.go('/level-map'),
                  onHint: () {
                    final cubit = context.read<GameplayCubit>();
                    if (state.pieces.any((p) => p.isHinted)) {
                      cubit.clearHint();
                      return;
                    }
                    final found = cubit.requestHint();
                    if (!found) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No moves available right now!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF7B3F00),
                        ),
                      );
                    }
                  },
                  isHintActive: state.pieces.any((p) => p.isHinted),
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
        );
      },
    );
  }
}
