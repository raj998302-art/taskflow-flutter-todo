import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';

/// A 3×3 connect-the-dots pattern lock grid, similar to Android's classic
/// pattern lock screen.
///
/// The user drags their finger across dots to draw a pattern. Each dot is
/// identified by a zero-based index `0..8`, laid out row by row:
///
/// ```
/// 0 1 2
/// 3 4 5
/// 6 7 8
/// ```
///
/// When the finger lifts, [onPatternComplete] is invoked with the ordered
/// list of node indices that were hit (for example `[0, 1, 2, 5, 8]`). An
/// empty list is delivered if nothing was drawn. Optional live feedback is
/// available through [onPatternChange], which fires whenever a new node is
/// added during the drag.
///
/// When [enabled] is `false` the widget ignores all touch — useful while a
/// verification animation is playing.
class PatternLockView extends StatefulWidget {
  /// Creates a pattern lock view.
  const PatternLockView({
    super.key,
    required this.onPatternComplete,
    this.onPatternChange,
    this.dotCount = 3,
    this.dotRadius = 16.0,
    this.strokeWidth = 4.0,
    this.size = 280,
    this.enabled = true,
  });

  /// Invoked with the final ordered list of node indices when the finger
  /// lifts. Empty list if no dot was hit.
  final ValueChanged<List<int>> onPatternComplete;

  /// Optional, fired on every newly added node during the drag.
  final ValueChanged<List<int>>? onPatternChange;

  /// Grid dimension (3 means a 3×3 grid). Defaults to 3.
  final int dotCount;

  /// Base radius of every dot, in logical pixels.
  final double dotRadius;

  /// Width of the connector lines, in logical pixels.
  final double strokeWidth;

  /// Side length of the square area the grid occupies.
  final double size;

  /// When `false`, touch events are ignored.
  final bool enabled;

  @override
  State<PatternLockView> createState() => _PatternLockViewState();
}

class _PatternLockViewState extends State<PatternLockView> {
  /// Indices of the dots the user has dragged through, in hit order.
  final List<int> _selectedNodes = <int>[];

  /// Current finger position (in widget coordinates) while dragging, or
  /// `null` when no drag is in progress.
  Offset? _currentPoint;

  bool _clearScheduled = false;

  /// Total number of dots in the grid (dotCount × dotCount).
  int get _nodeCount => widget.dotCount * widget.dotCount;

  /// Computes the centre [Offset] of a node given its index.
  Offset _nodePosition(int index) {
    final int row = index ~/ widget.dotCount;
    final int col = index % widget.dotCount;
    final double cell = widget.size / (widget.dotCount + 1);
    return Offset(
      cell * (col + 1),
      cell * (row + 1),
    );
  }

  /// Returns the index of the closest unselected node within
  /// `dotRadius + 8` of [point], or `null` if none qualifies.
  int? _hitTest(Offset point) {
    final double threshold = widget.dotRadius + 8;
    for (int i = 0; i < _nodeCount; i++) {
      if (_selectedNodes.contains(i)) continue;
      final Offset pos = _nodePosition(i);
      if ((pos - point).distance <= threshold) {
        return i;
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    final Offset local = details.localPosition;
    final int? hit = _hitTest(local);
    if (hit != null) {
      _addNode(hit);
    }
    setState(() => _currentPoint = local);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    final Offset local = details.localPosition;
    final int? hit = _hitTest(local);
    if (hit != null) {
      _addNode(hit);
    }
    setState(() => _currentPoint = local);
  }

  void _onPanEnd(DragEndDetails _) {
    if (!widget.enabled) return;
    setState(() => _currentPoint = null);
    widget.onPatternComplete(List<int>.unmodifiable(_selectedNodes));
    _clearScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _clearScheduled = false;
      setState(_selectedNodes.clear);
    });
  }

  void _addNode(int index) {
    _selectedNodes.add(index);
    widget.onPatternChange?.call(List<int>.unmodifiable(_selectedNodes));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PatternPainter(
              selectedNodes: List<int>.of(_selectedNodes),
              currentPoint: _currentPoint,
              nodePosition: _nodePosition,
              nodeCount: _nodeCount,
              dotRadius: widget.dotRadius,
              strokeWidth: widget.strokeWidth,
              lineColor: AppColors.primary,
              filledColor: AppColors.primary,
              hollowColor: colors.onSurfaceVariant,
              glowColor: AppColors.primary,
              clearScheduled: _clearScheduled,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms);
  }
}

/// Custom painter that draws the pattern lock grid.
///
/// Draws hollow dots for unselected nodes, filled dots with a soft radial
/// glow for selected nodes, connector lines between consecutive selected
/// nodes, and (while the finger is down) a trailing line from the last
/// selected node to the current finger position.
class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.selectedNodes,
    required this.currentPoint,
    required this.nodePosition,
    required this.nodeCount,
    required this.dotRadius,
    required this.strokeWidth,
    required this.lineColor,
    required this.filledColor,
    required this.hollowColor,
    required this.glowColor,
    required this.clearScheduled,
  });

  final List<int> selectedNodes;
  final Offset? currentPoint;
  final Offset Function(int) nodePosition;
  final int nodeCount;
  final double dotRadius;
  final double strokeWidth;
  final Color lineColor;
  final Color filledColor;
  final Color hollowColor;
  final Color glowColor;
  final bool clearScheduled;

  Paint _linePaint() => Paint()
    ..color = lineColor.withValues(alpha: 0.85)
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  Paint _trailPaint() => Paint()
    ..color = lineColor.withValues(alpha: 0.4)
    ..strokeWidth = strokeWidth * 0.75
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  Paint _hollowPaint() => Paint()
    ..color = hollowColor.withValues(alpha: 0.9)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  Paint _filledPaint() => Paint()
    ..color = filledColor
    ..style = PaintingStyle.fill;

  Paint _glowPaint(Offset center, double radius) => Paint()
    ..shader = RadialGradient(
      colors: <Color>[
        glowColor.withValues(alpha: 0.45),
        glowColor.withValues(alpha: 0.0),
      ],
      stops: const <double>[0.0, 1.0],
    ).createShader(
      Rect.fromCircle(center: center, radius: radius),
    );

  @override
  void paint(Canvas canvas, Size size) {
    // Connector lines between consecutive selected nodes.
    if (selectedNodes.length > 1) {
      final Path path = Path();
      final Offset first = nodePosition(selectedNodes.first);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < selectedNodes.length; i++) {
        final Offset p = nodePosition(selectedNodes[i]);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, _linePaint());
    }

    // Trailing line from the last selected node to the finger.
    if (currentPoint != null &&
        selectedNodes.isNotEmpty &&
        !clearScheduled) {
      final Offset last = nodePosition(selectedNodes.last);
      canvas.drawLine(last, currentPoint!, _trailPaint());
    }

    // Dots — hollow for unselected, filled + glow for selected.
    final Set<int> selected = selectedNodes.toSet();
    for (int i = 0; i < nodeCount; i++) {
      final Offset pos = nodePosition(i);
      if (selected.contains(i)) {
        final double glow = dotRadius * 2.6;
        canvas.drawCircle(pos, glow, _glowPaint(pos, glow));
        canvas.drawCircle(pos, dotRadius * 1.3, _filledPaint());
      } else {
        canvas.drawCircle(pos, dotRadius * 0.6, _hollowPaint());
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) {
    return old.selectedNodes != selectedNodes ||
        old.currentPoint != currentPoint ||
        old.clearScheduled != clearScheduled ||
        old.dotRadius != dotRadius ||
        old.strokeWidth != strokeWidth ||
        old.lineColor != lineColor ||
        old.filledColor != filledColor ||
        old.hollowColor != hollowColor ||
        old.glowColor != glowColor;
  }
}
