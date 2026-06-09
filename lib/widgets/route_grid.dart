import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/route_controller.dart';

/// Renders the Site Paver grid and turns drags into road moves.
/// Pure Flutter — cells are widgets, the road line is a [CustomPaint] overlay.
class RouteGrid extends StatefulWidget {
  const RouteGrid({
    super.key,
    required this.controller,
    required this.blockAsset,
    required this.onEnter,
    required this.onDragStart,
    this.roadColor = AppColors.accent,
  });

  final RouteController controller;
  final String blockAsset;
  final void Function(int row, int col) onEnter;
  final VoidCallback onDragStart;
  final Color roadColor;

  @override
  State<RouteGrid> createState() => _RouteGridState();
}

class _RouteGridState extends State<RouteGrid> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final rows = controller.rows;
    final cols = controller.cols;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          constraints.maxWidth / cols,
          constraints.maxHeight / rows,
        );
        final gridW = cell * cols;
        final gridH = cell * rows;

        void handle(Offset local) {
          final c = (local.dx / cell).floor();
          final r = (local.dy / cell).floor();
          if (r < 0 || c < 0 || r >= rows || c >= cols) return;
          widget.onEnter(r, c);
        }

        return Center(
          child: SizedBox(
            width: gridW,
            height: gridH,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => handle(d.localPosition),
              onPanStart: (d) {
                widget.onDragStart();
                handle(d.localPosition);
              },
              onPanUpdate: (d) => handle(d.localPosition),
              child: Container(
                // Border drawn via foregroundDecoration so it never insets the
                // child grid (avoids right/bottom overflow).
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0A22),
                  borderRadius: BorderRadius.circular(cell * 0.18),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cell * 0.18),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Cell plates / markers / paved blocks.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var r = 0; r < rows; r++)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var c = 0; c < cols; c++)
                                _CellTile(
                                  size: cell,
                                  wall: controller.level.isWall(r, c),
                                  paved: controller.isPaved(r, c),
                                  head: controller.isHead(r, c),
                                  start: controller.isStart(r, c),
                                  exit: controller.isExit(r, c),
                                  blockAsset: widget.blockAsset,
                                ),
                            ],
                          ),
                      ],
                    ),
                    // Road line overlay.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _RoadPainter(
                            path: controller.path,
                            cols: cols,
                            cell: cell,
                            color: widget.roadColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CellTile extends StatelessWidget {
  const _CellTile({
    required this.size,
    required this.wall,
    required this.paved,
    required this.head,
    required this.start,
    required this.exit,
    required this.blockAsset,
  });

  final double size;
  final bool wall;
  final bool paved;
  final bool head;
  final bool start;
  final bool exit;
  final String blockAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: wall ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: wall ? Colors.transparent : Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: wall ? null : _content(),
    );
  }

  Widget _content() {
    if (paved) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(size * 0.06),
            child: Image.asset(blockAsset, fit: BoxFit.fill, gaplessPlayback: true),
          ),
          if (start) _badge(Icons.flag_circle_rounded, AppColors.accent),
          if (exit) _badge(Icons.verified_rounded, Colors.greenAccent),
          if (head && !exit) _badge(Icons.circle, Colors.white),
        ],
      );
    }
    if (start) return _marker(Icons.play_circle_fill_rounded, AppColors.accent, 'START');
    if (exit) return _marker(Icons.outlined_flag_rounded, Colors.greenAccent, 'EXIT');
    return const SizedBox.shrink();
  }

  Widget _marker(IconData icon, Color color, String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: size * 0.5),
          if (size > 38)
            Text(label,
                style: AppTextStyles.body(size: size * 0.16, color: color)),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, Color color) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(size * 0.04),
        child: Icon(icon, color: color, size: size * 0.3),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.path,
    required this.cols,
    required this.cell,
    required this.color,
  });

  final List<int> path;
  final int cols;
  final double cell;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final line = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.16
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final p = Path();
    for (var i = 0; i < path.length; i++) {
      final r = path[i] ~/ cols;
      final c = path[i] % cols;
      final center = Offset((c + 0.5) * cell, (r + 0.5) * cell);
      if (i == 0) {
        p.moveTo(center.dx, center.dy);
      } else {
        p.lineTo(center.dx, center.dy);
      }
    }
    canvas.drawPath(p, line);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.cell != cell ||
      oldDelegate.color != color;
}
