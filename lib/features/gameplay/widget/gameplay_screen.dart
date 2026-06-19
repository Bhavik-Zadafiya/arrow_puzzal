import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../data/level_1.dart';
import '../data/level_definition.dart';
import '../provider/gameplay_cubit.dart';
import '../provider/gameplay_state.dart';
import 'continue_dialog.dart';
import 'game_grid.dart';
import 'game_top_bar.dart';
import 'level_complete_overlay.dart';

class GameplayScreen extends StatelessWidget {
  const GameplayScreen({super.key, this.level});

  /// Pass null to default to Level 1.
  final LevelDefinition? level;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameplayCubit(level ?? kLevel1),
      child: const _GameplayView(),
    );
  }
}

class _GameplayView extends StatelessWidget {
  const _GameplayView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameplayCubit, GameplayState>(
      listenWhen: (prev, curr) => prev.phase != curr.phase,
      listener: (context, state) {
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
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Stack(
            children: [
              Column(
                children: [
                  GameTopBar(
                    levelId: state.level.id,
                    mistakes: state.mistakes,
                    maxMistakes: GameplayState.maxMistakes,
                    onClose: () => context.go('/level-map'),
                  ),
                  const Expanded(child: GameGrid()),
                  const SizedBox(height: 32),
                ],
              ),

              // Level complete overlay — animated in on top of everything
              if (state.phase == GamePhase.levelComplete)
                Positioned.fill(
                  child: LevelCompleteOverlay(
                    mistakes: state.mistakes,
                    onNext: () {
                      // TODO: load next level definition when level catalogue is built
                      context.go('/level-map');
                    },
                    onHome: () => context.go('/level-map'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
