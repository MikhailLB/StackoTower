import 'package:flutter/material.dart';

import '../app/skyline.dart';
import '../game/campaign.dart';
import '../game/tower_engine.dart';
import '../main.dart';
import 'play_screen.dart';

/// A vertical climbing road-map: floor 1 at the bottom, the tower rises up.
/// Auto-scrolls to the player's current floor so it's never buried.
class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final _scroll = ScrollController();
  static const double _rowH = 104;
  static const _lanes = [0.26, 0.5, 0.74];
  static const _lanePattern = [0, 1, 2, 1];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    if (!_scroll.hasClients) return;
    final total = campaignCount;
    final current = (progress.highestUnlockedLevel).clamp(1, total);
    final tFromTop = total - current; // 0 at top
    final y = tFromTop * _rowH + _rowH / 2;
    final target =
        (y - _scroll.position.viewportDimension / 2).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _play(CampaignLevel l) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlayScreen(mode: GameMode.campaign, level: l),
    ));
    if (mounted) setState(() => _scrollToCurrent());
  }

  @override
  Widget build(BuildContext context) {
    final total = campaignCount;
    final contentH = total * _rowH + 60;
    return Scaffold(
      body: SkyBackdrop(
        glowColor: Sky.cyan,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _back(),
                    const SizedBox(width: 12),
                    Text('THE CLIMB', style: Sky.display(size: 24)),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: Sky.amber, size: 20),
                    const SizedBox(width: 4),
                    Text('${progress.totalStars}', style: Sky.number(size: 16)),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    return SingleChildScrollView(
                      controller: _scroll,
                      child: SizedBox(
                        width: w,
                        height: contentH,
                        child: Stack(
                          children: [
                            // Connecting path.
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _PathPainter(
                                  total: total,
                                  rowH: _rowH,
                                  lanes: _lanes,
                                  lanePattern: _lanePattern,
                                  reached: progress.highestUnlockedLevel,
                                ),
                              ),
                            ),
                            // Nodes.
                            for (var i = 0; i < total; i++)
                              _node(i, w, contentH),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _node(int i, double width, double contentH) {
    final level = campaign[i];
    final number = level.number;
    final tFromTop = campaignCount - 1 - i;
    final cy = tFromTop * _rowH + _rowH / 2;
    final lane = _lanes[_lanePattern[tFromTop % _lanePattern.length]];
    final cx = width * lane;

    final unlocked = progress.isLevelUnlocked(number);
    final stars = progress.starsFor(number);
    final isCurrent = number == progress.highestUnlockedLevel;
    final color = unlocked ? (isCurrent ? Sky.amber : Sky.cyan) : Sky.muted;

    return Positioned(
      left: cx - 46,
      top: cy - 46,
      width: 92,
      height: 92,
      child: GestureDetector(
        onTap: unlocked ? () => _play(level) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
                boxShadow: unlocked ? Sky.glow(color, blur: isCurrent ? 18 : 10) : null,
              ),
              child: unlocked
                  ? Text('$number', style: Sky.number(size: 20))
                  : const Icon(Icons.lock_rounded, color: Sky.muted, size: 22),
            ),
            const SizedBox(height: 3),
            if (unlocked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var s = 0; s < 3; s++)
                    Icon(
                      s < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: s < stars ? Sky.amber : Sky.muted,
                      size: 12,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _back() => GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Sky.panel,
            shape: BoxShape.circle,
            border: Border.all(color: Sky.violet.withValues(alpha: 0.5), width: 1.4),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Sky.text, size: 22),
        ),
      );
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.total,
    required this.rowH,
    required this.lanes,
    required this.lanePattern,
    required this.reached,
  });

  final int total;
  final double rowH;
  final List<double> lanes;
  final List<int> lanePattern;
  final int reached;

  @override
  void paint(Canvas canvas, Size size) {
    Offset nodeAt(int tFromTop) {
      final cy = tFromTop * rowH + rowH / 2;
      final cx = size.width * lanes[lanePattern[tFromTop % lanePattern.length]];
      return Offset(cx, cy);
    }

    for (var t = 0; t < total - 1; t++) {
      final a = nodeAt(t);
      final b = nodeAt(t + 1);
      // level numbers: number = total - tFromTop
      final lowerNumber = total - (t + 1);
      final unlocked = lowerNumber < reached;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = (unlocked ? Sky.cyan : Sky.muted).withValues(alpha: 0.35);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.reached != reached;
}
