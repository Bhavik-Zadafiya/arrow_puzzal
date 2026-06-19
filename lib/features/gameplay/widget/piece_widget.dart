import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/level_definition.dart';
import '../provider/gameplay_state.dart';
import 'piece_painter.dart';

class PieceWidget extends StatefulWidget {
  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.onTap,
    required this.onExitComplete,
  });

  final GamePiece piece;
  final double cellSize;
  final VoidCallback onTap;
  final VoidCallback onExitComplete;

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget>
    with TickerProviderStateMixin {
  late final AnimationController _exitCtrl;
  late final AnimationController _shakeCtrl;
  bool _showError = false;

  @override
  void initState() {
    super.initState();

    _exitCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _exitCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onExitComplete();
        });
      }
    });

    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _showError = false);
      }
    });
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
  }

  @override
  void dispose() {
    _exitCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Offset _exitOffset(double t) {
    final dist = widget.cellSize * 7 * Curves.easeIn.transform(t);
    return switch (widget.piece.direction) {
      Direction.right => Offset(dist, 0),
      Direction.left  => Offset(-dist, 0),
      Direction.up    => Offset(0, -dist),
      Direction.down  => Offset(0, dist),
    };
  }

  double _shakeX(double t) =>
      math.sin(t * math.pi * 4) * widget.cellSize * 0.09;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_exitCtrl, _shakeCtrl]),
        builder: (_, child) => Transform.translate(
          offset: _exitOffset(_exitCtrl.value) +
              Offset(_shakeX(_shakeCtrl.value), 0),
          child: child,
        ),
        child: CustomPaint(
          size: Size(widget.cellSize, widget.cellSize),
          painter: PiecePainter(
            direction: widget.piece.direction,
            isError: _showError,
          ),
        ),
      ),
    );
  }
}
