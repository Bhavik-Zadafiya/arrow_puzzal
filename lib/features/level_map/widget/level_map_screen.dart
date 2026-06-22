import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../provider/level_map_cubit.dart';
import '../provider/level_map_state.dart';
import 'bottom_nav_bar.dart';
import 'level_node.dart';
import 'level_path_painter.dart';
import 'top_status_bar.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LevelMapCubit(),
      child: const _LevelMapView(),
    );
  }
}

class _LevelMapView extends StatelessWidget {
  const _LevelMapView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LevelMapCubit, LevelMapState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: TopStatusBar(
            lifelineCount: state.lifelineCount,
            lifelineMax: state.lifelineMax,
            regenSecondsRemaining: state.regenSecondsRemaining,
          ),
          body: Stack(
            children: [
              _buildBody(context, state),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GameBottomNavBar(
                  activeIndex: state.activeTab,
                  onTap: context.read<LevelMapCubit>().setActiveTab,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LevelMapState state) {
    return switch (state.activeTab) {
      0 => _MapTab(levels: state.levels),
      1 => _PlaceholderTab(message: AppStrings.dailyPlaceholder),
      _ => _PlaceholderTab(message: AppStrings.settingsPlaceholder),
    };
  }
}

// ============================================================================
// Map tab
// ============================================================================

class _MapTab extends StatefulWidget {
  const _MapTab({required this.levels});
  final List<LevelData> levels;

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  late final ScrollController _scrollController;

  static const double _canvasWidth   = 320;
  static const double _nodeSpacingY  = 120.0;
  static const double _topPad        = kToolbarHeight + 80;
  // Extra space so level 1 clears the floating nav bar on all screen sizes
  static const double _bottomPad     = 200.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLevel());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLevel() {
    final currentIndex =
        widget.levels.indexWhere((l) => l.status == LevelStatus.current);
    if (currentIndex == -1) return;

    final canvasHeight = _canvasHeight(widget.levels.length);
    final nodeY = canvasHeight - _topPad - (currentIndex * _nodeSpacingY);
    final target = (nodeY - 300).clamp(0.0, double.infinity);
    // Jump instantly — no scroll animation on load
    _scrollController.jumpTo(target);
  }

  static double _canvasHeight(int count) =>
      _topPad + (count * _nodeSpacingY) + _bottomPad;

  /// Node positions in the 320-wide virtual column (index 0 = bottom = level 1).
  List<Offset> _buildNodePositions(int count, double canvasHeight) {
    const leftX   = _canvasWidth * 0.25;
    const rightX  = _canvasWidth * 0.75;
    const centerX = _canvasWidth * 0.50;

    return List.generate(count, (i) {
      final y = canvasHeight - _bottomPad - (i * _nodeSpacingY);
      final x = switch (i % 4) {
        0 => leftX,
        1 => centerX,
        2 => rightX,
        _ => centerX,
      };
      return Offset(x, y);
    });
  }

  // --------------------------------------------------------------------------
  // Decorative element builders
  // --------------------------------------------------------------------------

  List<Widget> _buildRuneStones(List<Offset> nodes, double colOffset) {
    final rng     = math.Random(42);
    final widgets = <Widget>[];

    for (int i = 2; i < nodes.length; i += 6) {
      final pos    = nodes[i];
      final isLeft = (i ~/ 6) % 2 == 0;
      final dx     = colOffset + pos.dx + (isLeft ? -105.0 : 68.0);
      final tilt   = (rng.nextDouble() - 0.5) * 0.35;
      final size   = 52.0 + rng.nextDouble() * 14;

      widgets.add(
        Positioned(
          left: dx,
          top:  pos.dy - size * 0.55,
          child: Transform.rotate(
            angle: tilt,
            child: Opacity(
              opacity: 0.82,
              child: Image.asset(AppAssets.stone, width: size, height: size * 1.2),
            ),
          )
              .animate(delay: (i * 40).ms)
              .fadeIn(duration: 700.ms, curve: Curves.easeOut)
              .moveY(begin: 14, end: 0, duration: 700.ms, curve: Curves.easeOut),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildCompassRoses(
    List<Offset> nodes,
    double colOffset,
    double screenWidth,
    List<LevelData> levels,
  ) {
    final widgets = <Widget>[];
    // Place at start and near every 20th level
    final indices = [0, 19, 39].where((i) => i < nodes.length).toList();

    for (final i in indices) {
      final pos    = nodes[i];
      final isLeft = i % 2 == 0;
      final dx     = isLeft
          ? (colOffset + pos.dx - 115).clamp(4.0, screenWidth - 100)
          : (colOffset + pos.dx + 38).clamp(4.0, screenWidth - 100);

      widgets.add(
        Positioned(
          left: dx,
          top:  pos.dy - 48,
          child: _SpinningCompass(delay: (i * 80).ms),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildSparkles(double canvasHeight, double screenWidth) {
    final rng     = math.Random(77);
    final widgets = <Widget>[];

    for (int i = 0; i < 22; i++) {
      final x     = rng.nextDouble() * (screenWidth - 40) + 10;
      final y     = rng.nextDouble() * canvasHeight;
      final size  = 18.0 + rng.nextDouble() * 26;
      final delay = (rng.nextDouble() * 3200).toInt();
      final phase = rng.nextDouble() * 2000;

      widgets.add(
        Positioned(
          left: x - size / 2,
          top:  y - size / 2,
          child: _PulsingSparkle(
            size:  size,
            delay: delay.ms,
            phase: phase.toInt().ms,
          ),
        ),
      );
    }
    return widgets;
  }

  // Ground fog removed — replaced with subtle bottom gradient fade
  Widget _buildBottomFade(double screenWidth) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundDark.withValues(alpha: 0.0),
              AppColors.backgroundDark.withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------

  double _nodeHalfSize(LevelData level) {
    if (level.isMilestone) return 55.8; // 72 * 1.55 / 2
    if (level.status == LevelStatus.current) return 42.0; // 56 * 1.5 / 2
    return 28.0; // 56 / 2
  }

  @override
  Widget build(BuildContext context) {
    final levels      = widget.levels;
    final canvasHeight = _canvasHeight(levels.length);

    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth   = constraints.maxWidth;
      final colOffset     = (screenWidth - _canvasWidth) / 2;
      final nodePositions = _buildNodePositions(levels.length, canvasHeight);

      return SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          width: screenWidth,
          height: canvasHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── 1. Seamlessly tiled background (mirror mode = no seams) ─
              Positioned.fill(
                child: _SeamlessBackground(
                  totalHeight: canvasHeight,
                  screenWidth: screenWidth,
                ),
              ),
              // Dark overlay — keeps bg subtle so nodes/path stay readable
              Positioned.fill(
                child: Container(
                  color: AppColors.backgroundDark.withValues(alpha: 0.62),
                ),
              ),

              // ── 2. Bottom gradient fade ──────────────────────────────────
              _buildBottomFade(screenWidth),

              // ── 3. Path ribbon (centered 320px column) ──────────────────
              Positioned(
                left: colOffset,
                top:  0,
                width:  _canvasWidth,
                height: canvasHeight,
                child: CustomPaint(
                  painter: LevelPathPainter(nodePositions: nodePositions),
                ),
              ),

              // ── 4. Rune stone props ─────────────────────────────────────
              ..._buildRuneStones(nodePositions, colOffset),

              // ── 5. Compass rose accents ──────────────────────────────────
              ..._buildCompassRoses(nodePositions, colOffset, screenWidth, levels),

              // ── 6. Floating sparkle stars ────────────────────────────────
              ..._buildSparkles(canvasHeight, screenWidth),

              // ── 7. Level nodes ───────────────────────────────────────────
              ...List.generate(levels.length, (i) {
                final pos   = nodePositions[i];
                final level = levels[i];
                final half  = _nodeHalfSize(level);

                return Positioned(
                  left: colOffset + pos.dx - half,
                  top:  pos.dy - half,
                  child: LevelNode(
                    level: level,
                    onTap: () => context.go('/gameplay?level=${level.id}'),
                  )
                      .animate(delay: (i * 35).ms)
                      .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                      .moveY(begin: 16, end: 0, duration: 380.ms, curve: Curves.easeOut),
                );
              }),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 280.ms, curve: Curves.easeOut);
    });
  }
}

// ============================================================================
// Helper widgets
// ============================================================================

/// Loads the bg image once and tiles it seamlessly using [ui.ImageShader]
/// with [TileMode.mirror] — the image is flipped at every tile boundary so
/// there is never a visible seam, even on infinite scroll.
class _SeamlessBackground extends StatefulWidget {
  const _SeamlessBackground({
    required this.totalHeight,
    required this.screenWidth,
  });
  final double totalHeight;
  final double screenWidth;

  @override
  State<_SeamlessBackground> createState() => _SeamlessBackgroundState();
}

class _SeamlessBackgroundState extends State<_SeamlessBackground> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data  = await rootBundle.load(AppAssets.bgSceneryLeft);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) {
      return Container(color: AppColors.backgroundDark);
    }
    return CustomPaint(
      size: Size(widget.screenWidth, widget.totalHeight),
      painter: _SeamlessPainter(
        image:       img,
        screenWidth: widget.screenWidth,
      ),
    );
  }
}

class _SeamlessPainter extends CustomPainter {
  const _SeamlessPainter({required this.image, required this.screenWidth});
  final ui.Image image;
  final double screenWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale tile so it fills the screen width at native aspect ratio
    final tileW = screenWidth;
    final tileH = screenWidth * image.height / image.width;

    final scaleX = tileW / image.width;
    final scaleY = tileH / image.height;
    final matrix = Float64List.fromList([
      scaleX, 0,      0, 0,
      0,      scaleY, 0, 0,
      0,      0,      1, 0,
      0,      0,      0, 1,
    ]);

    final paint = Paint()
      ..shader = ui.ImageShader(
        image,
        TileMode.mirror, // horizontal mirror — no seam
        TileMode.mirror, // vertical mirror — no seam on scroll
        matrix,
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SeamlessPainter old) => old.image != image;
}

class _SpinningCompass extends StatelessWidget {
  const _SpinningCompass({required this.delay});
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.18,
      child: Image.asset(AppAssets.compassRose, width: 88, height: 88)
          .animate(delay: delay, onPlay: (c) => c.repeat())
          .rotate(duration: 28000.ms, begin: 0, end: 1, curve: Curves.linear),
    );
  }
}

class _PulsingSparkle extends StatelessWidget {
  const _PulsingSparkle({
    required this.size,
    required this.delay,
    required this.phase,
  });
  final double size;
  final Duration delay;
  final Duration phase;

  @override
  Widget build(BuildContext context) {
    return Image.asset(AppAssets.starBurst, width: size, height: size)
        .animate(delay: delay, onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.55,
          end: 1.0,
          duration: Duration(milliseconds: 1800 + phase.inMilliseconds % 1200),
          curve: Curves.easeInOut,
        )
        .fade(
          begin: 0.15,
          end: 0.75,
          duration: Duration(milliseconds: 1800 + phase.inMilliseconds % 1200),
          curve: Curves.easeInOut,
        );
  }
}

// ============================================================================
// Placeholder tabs
// ============================================================================

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textWarm.withValues(alpha: 0.4),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
