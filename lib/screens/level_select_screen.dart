import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/route_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/site_background.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';

/// Vertical "route map" of lots — each lot is a node on a path you progress
/// along, distinct from a plain grid of buttons.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    progress.addListener(_onChanged);
  }

  @override
  void dispose() {
    progress.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startLevel(RouteLevel level) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)),
    );
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  @override
  Widget build(BuildContext context) {
    final solved = progress.completedLevels.length;
    final total = routeLevels.length;

    return Scaffold(
      body: SiteBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        AudioService.instance.playSfx(Sfx.buttonClick);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SITE PLAN',
                              style: AppTextStyles.body(
                                      size: 10, color: NeonColors.cyan)
                                  .copyWith(letterSpacing: 3)),
                          Text('Choose a Lot',
                              style: AppTextStyles.title(size: 26)),
                        ],
                      ),
                    ),
                    CoinChip(coins: progress.coins),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : solved / total,
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$solved/$total',
                        style: AppTextStyles.button(
                            size: 13, color: AppColors.accent)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 16),
                    itemCount: routeLevels.length,
                    itemBuilder: (_, index) {
                      final level = routeLevels[index];
                      return _RouteNode(
                        level: level,
                        unlocked: progress.isLevelUnlocked(level.levelNumber),
                        completed:
                            progress.isLevelCompleted(level.levelNumber),
                        first: index == 0,
                        last: index == routeLevels.length - 1,
                        onTap: progress.isLevelUnlocked(level.levelNumber)
                            ? () => _startLevel(level)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteNode extends StatelessWidget {
  const _RouteNode({
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.first,
    required this.last,
    required this.onTap,
  });

  final RouteLevel level;
  final bool unlocked;
  final bool completed;
  final bool first;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nodeColor = completed
        ? AppColors.accent
        : (unlocked ? NeonColors.violet : Colors.white24);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connector + node
          SizedBox(
            width: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: first ? null : 0,
                  bottom: last ? null : 0,
                  child: Container(
                    width: 3,
                    color: unlocked
                        ? AppColors.accent.withValues(alpha: 0.35)
                        : Colors.white10,
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.accent
                        : NeonColors.cardFillDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                    boxShadow: completed
                        ? [
                            BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                blurRadius: 10)
                          ]
                        : null,
                  ),
                  child: Center(
                    child: completed
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.textDark, size: 20)
                        : unlocked
                            ? Text('${level.levelNumber}',
                                style: AppTextStyles.button(
                                    size: 15, color: AppColors.text))
                            : const Icon(Icons.lock_rounded,
                                color: Colors.white38, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: NeonCard(
                onTap: onTap,
                glow: completed,
                edge: completed ? AppColors.accent : NeonColors.violet,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unlocked ? level.name : 'Locked',
                            style: AppTextStyles.button(
                              size: 17,
                              color: unlocked ? AppColors.text : Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${level.cols}×${level.rows} lot · ${level.plotCount} plots',
                            style: AppTextStyles.body(
                              size: 12,
                              color:
                                  unlocked ? AppColors.textMuted : Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on_rounded,
                                color:
                                    unlocked ? AppColors.accent : Colors.white24,
                                size: 14),
                            const SizedBox(width: 3),
                            Text('${level.coinReward}',
                                style: AppTextStyles.button(
                                  size: 14,
                                  color: unlocked
                                      ? AppColors.accent
                                      : Colors.white24,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          completed
                              ? Icons.replay_rounded
                              : (unlocked
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_rounded),
                          color: unlocked ? AppColors.text : Colors.white24,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
