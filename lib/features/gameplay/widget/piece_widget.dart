import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  });

  final GamePiece piece;
  final double cellSize;
  final double gridWidth;
  final double gridHeight;
  final double pixelsToEdge;
  final VoidCallback onTap;
  final VoidCallback onExitComplete;

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget>
    with TickerProviderStateMixin {
  static const _exitDuration  = Duration(milliseconds: 500);
  static const _hintDuration  = Duration(milliseconds: 480);

  late final AnimationController _exitCtrl;
  late final AnimationController _shakeCtrl;
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

    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _showError = false);
        }
      });

    // Bounce animation: repeating up-down jump for hinted piece.
    _hintCtrl = AnimationController(
      duration: _hintDuration,
      vsync: this,
    );

    if (widget.piece.isHinted) _startHint();
  }

  @override
  void didUpdateWidget(PieceWidget old) {
    super.didUpdateWidget(old);

    if (widget.piece.isExiting && !old.piece.isExiting) {
      _exitCtrl.forward(from: 0);
    }
    if (widget.piece.shakeCount > old.piece.shakeCount) {
      setState(() => _showError = true);
      _shakeCtrl.forward(from: 0);
    }
    if (widget.piece.isHinted && !old.piece.isHinted) {
      _startHint();
    }
    if (!widget.piece.isHinted && old.piece.isHinted) {
      _stopHint();
    }
  }

  void _startHint() => _hintCtrl.repeat(reverse: true);
  void _stopHint()  => _hintCtrl
    ..stop()
    ..value = 0;

  @override
  void dispose() {
    _exitCtrl.dispose();
    _shakeCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  double _shakeX(double t) =>
      math.sin(t * math.pi * 4) * widget.cellSize * 0.09;

  // Smooth bounce: 0 → peak → 0 using a sine curve.
  double _bounceY(double t) =>
      -math.sin(t * math.pi) * widget.cellSize * 0.45;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_exitCtrl, _shakeCtrl, _hintCtrl]),
      builder: (_, __) => Transform.translate(
        offset: Offset(
          _shakeX(_shakeCtrl.value),
          _bounceY(_hintCtrl.value),
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
            ),
          ),
        ),
      ),
    );
  }
}
