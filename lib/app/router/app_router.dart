import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/daily_service.dart';
import '../../features/gameplay/data/level_service.dart';
import '../../features/gameplay/widget/gameplay_screen.dart';
import '../../features/level_map/widget/level_map_screen.dart';
import '../../features/settings/widget/settings_screen.dart';
import '../../features/settings/widget/privacy_policy_screen.dart';
import '../../features/splash/widget/splash_screen.dart';
import '../../features/tutorial/widget/tutorial_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/level-map',
      builder: (context, state) => const LevelMapScreen(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/gameplay',
      builder: (context, state) {
        final params = state.uri.queryParameters;

        // Daily puzzle route: /gameplay?daily=1
        if (params['daily'] == '1') {
          return GameplayScreen(
            key: const ValueKey('daily'),
            levelNumber: 0,
            level: DailyService.instance.todayLevel,
            isDaily: true,
          );
        }

        // Normal level route: /gameplay?level=N
        final n = int.tryParse(params['level'] ?? '1') ?? 1;
        final clamped = n.clamp(1, 500);
        return GameplayScreen(
          key: ValueKey('level_$clamped'),
          levelNumber: clamped,
          level: levelForNumber(clamped),
        );
      },
    ),
  ],
);
