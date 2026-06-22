import 'package:go_router/go_router.dart';
import '../../features/gameplay/data/level_service.dart';
import '../../features/gameplay/widget/gameplay_screen.dart';
import '../../features/level_map/widget/level_map_screen.dart';
import '../../features/splash/widget/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/level-map',
      builder: (context, state) => const LevelMapScreen(),
    ),
    GoRoute(
      path: '/gameplay',
      builder: (context, state) {
        final lvl = state.uri.queryParameters['level'];
        final n   = int.tryParse(lvl ?? '1') ?? 1;
        return GameplayScreen(level: levelForNumber(n.clamp(1, 9999)));
      },
    ),
  ],
);
