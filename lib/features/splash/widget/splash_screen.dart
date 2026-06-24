import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/settings_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (!SettingsService.instance.tutorialSeen) {
      context.go('/tutorial');
    } else {
      context.go('/level-map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFD4B97A), AppColors.accentGold, Color(0xFFF0D080)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(b),
              child: Text(
                AppStrings.appName,
                style: textTheme.displayLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            )
                .animate()
                .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                .scaleXY(begin: 0.88, end: 1.0, duration: 700.ms, curve: Curves.easeOut),
            const SizedBox(height: 12),
            Text(
              AppStrings.splashTagline,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
