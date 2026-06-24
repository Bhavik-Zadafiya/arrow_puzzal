import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/settings_service.dart';
import '../data/level_definition.dart';
import '../provider/gameplay_state.dart';
import 'piece_painter.dart';

class PieceWidget extends StatefulWidget {
  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.gridWidth,
    required this.gridHeight,
    required this.pixelsToEdge,
    required this.onTap,
    required this.onExitComplete,
    this.pieceColor = AppColors.textWarm,
  });

  final GamePiece piece;
  final double cellSize;
  final double gridWidth;
  final double gridHeight;
  final double pixelsToEdge;
  final VoidCallback onTap;
  final VoidCallback onExitComplete;
  final Color pieceColor;

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget>
    with TickerProviderStateMixin {
  static const _exitDuration   = Duration(milliseconds: 500);
  static const _hintDuration   = Duration(milliseconds: 480);
  static const _lungeDuration  = Duration(milliseconds: 620); // water-wave needs more time
  static const _bumperDuration = Duration(milliseconds: 320);

  late final AnimationController _exitCtrl;
  late final AnimationController _lungeCtrl;
  late final AnimationController _bumperCtrl;
  late final AnimationController _hintCtrl;
  bool _showError = false;

  @override
  void initState() {
    super.initState();

    _exitCtrl = AnimationController(duration: _exitDuration, vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onExitComplete();
          });
        }
      });

    _lungeCtrl = AnimationController(duration: _lungeDuration, vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _showError = false);
        }
      });

    _bumperCtrl = AnimationController(duration: _bumperDuration, vsync: this);

    _hintCtrl = AnimationController(duration: _hintDuration, vsync: this);
    if (widget.piece.isHinted) _startHint();
  }

  @override
  void didUpdateWidget(PieceWidget old) {
    super.didUpdateWidget(old);

    if (widget.piece.isExiting && !old.piece.isExiting) {
      _exitCtrl.forward(from: 0);
      if (SettingsService.instance.hapticsEnabled) HapticFeedback.lightImpact();
    }
    if (widget.piece.shakeCount > old.piece.shakeCount) {
      setState(() => _showError = true);
      _lungeCtrl.forward(from: 0);
      if (SettingsService.instance.hapticsEnabled) HapticFeedback.mediumImpact();
    }
    if (widget.piece.bumperCount > old.piece.bumperCount) {
      _bumperCtrl.forward(from: 0);
    }
    if (widget.piece.isHinted && !old.piece.isHinted) _startHint();
    if (!widget.piece.isHinted && old.piece.isHinted) _stopHint();
  }

  void _startHint() => _hintCtrl.repeat(reverse: true);
  void _stopHint()  { _hintCtrl.stop(); _hintCtrl.value = 0; }

  @override
  void dispose() {
    _exitCtrl.dispose();
    _lungeCtrl.dispose();
    _bumperCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  /// Water-wave: damped sine oscillation in the exit direction.
  ///
  /// Formula: A · sin(t · 2.8π) · (1 − t)²
  ///   t=0.18 → peak forward  (+amplitude)
  ///   t=0.54 → peak backward (−amplitude × 0.46)  ← water sloshes back
  ///   t=0.89 → small forward (+amplitude × 0.11)   ← tiny residual ripple
  ///   t=1.00 → settled at 0
  Offset _lungeOffset(double t) {
    final amplitude = widget.cellSize * 0.42;
    final decay     = (1.0 - t) * (1.0 - t); // quadratic envelope
    final dist      = amplitude * math.sin(t * 2.8 * math.pi) * decay;
    return switch (widget.piece.direction) {
      Direction.right => Offset(dist, 0),
      Direction.left  => Offset(-dist, 0),
      Direction.up    => Offset(0, -dist),
      Direction.down  => Offset(0, dist),
    };
  }

  /// Bumper: small water-wave in the impact direction when another piece hits.
  Offset _bumperOffset(double t) {
    final dir       = widget.piece.bumperDirection ?? widget.piece.direction;
    final amplitude = widget.cellSize * 0.16;
    final decay     = (1.0 - t) * (1.0 - t);
    final dist      = amplitude * math.sin(t * 2.5 * math.pi) * decay;
    return switch (dir) {
      Direction.right => Offset(dist, 0),
      Direction.left  => Offset(-dist, 0),
      Direction.up    => Offset(0, -dist),
      Direction.down  => Offset(0, dist),
    };
  }

  // Smooth hint bounce: 0 → peak → 0
  double _bounceY(double t) =>
      -math.sin(t * math.pi) * widget.cellSize * 0.45;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_exitCtrl, _lungeCtrl, _bumperCtrl, _hintCtrl]),
      builder: (_, __) {
        final lunge  = _lungeOffset(_lungeCtrl.value);
        final bumper = _bumperOffset(_bumperCtrl.value);
        final hintDy = _bounceY(_hintCtrl.value);

        return Transform.translate(
          offset: Offset(
            lunge.dx + bumper.dx,
            lunge.dy + bumper.dy + hintDy,
          ),
          child: SizedBox(
            width: widget.gridWidth,
            height: widget.gridHeight,
            child: CustomPaint(
              size: Size(widget.gridWidth, widget.gridHeight),
              painter: PiecePainter(
                cells: widget.piece.cells,
                direction: widget.piece.direction,
                isError: _showError,
                isHinted: widget.piece.isHinted,
                cellSize: widget.cellSize,
                drainT: _exitCtrl.value,
                pixelsToEdge: widget.pixelsToEdge,
                pieceColor: widget.pieceColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
