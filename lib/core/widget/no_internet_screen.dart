import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/connectivity_service.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated icon ───────────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.boardSurface,
                    border: Border.all(
                      color: AppColors.accentGold.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.08),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.accentGold,
                    size: 44,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                        begin: 1.0,
                        end: 1.06,
                        duration: 1800.ms,
                        curve: Curves.easeInOut),

                const SizedBox(height: 32),

                // ── Title ───────────────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFD4B97A), AppColors.accentGold],
                  ).createShader(b),
                  child: const Text(
                    'No Connection',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),

                const SizedBox(height: 12),

                // ── Subtitle ────────────────────────────────────────────────
                Text(
                  'Please check your internet connection.\nArrowX needs connectivity for ads and rewards.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textWarm.withValues(alpha: 0.60),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms),

                const SizedBox(height: 40),

                // ── Retry button ────────────────────────────────────────────
                _RetryButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    // Re-init triggers a fresh connectivity check via the service stream.
    await ConnectivityService.instance.init();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _checking ? null : _retry,
        icon: _checking
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.backgroundDark),
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          _checking ? 'Checking…' : 'Try Again',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.backgroundDark,
          disabledBackgroundColor: AppColors.accentGold.withValues(alpha: 0.55),
          disabledForegroundColor: AppColors.backgroundDark.withValues(alpha: 0.60),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
