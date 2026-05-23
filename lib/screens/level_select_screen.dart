import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/level_config.dart';
import '../main.dart';
import '../services/audio_service.dart';
import 'game_screen.dart';

/// Grid of levels. Each card shows the level number, target blocks and coin
/// reward. Locked levels (beyond [progress.highestUnlockedLevel]) are dimmed.
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
    progress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startLevel(LevelConfig config) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(levelConfig: config),
      ),
    );
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A3E), Color(0xFF0D0D1F)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackButton(onTap: () {
                        AudioService.instance.playSfx(Sfx.buttonClick);
                        Navigator.of(context).pop();
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Level',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title(size: 32),
                        ),
                      ),
                      _CoinPill(coins: progress.coins),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: levels.length,
                      itemBuilder: (_, index) {
                        final config = levels[index];
                        final unlocked =
                            progress.isLevelUnlocked(config.levelNumber);
                        final completed =
                            progress.isLevelCompleted(config.levelNumber);
                        return _LevelCard(
                          config: config,
                          unlocked: unlocked,
                          completed: completed,
                          onTap: unlocked
                              ? () => _startLevel(config)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.config,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });

  final LevelConfig config;
  final bool unlocked;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = completed
        ? AppColors.accent
        : (unlocked ? Colors.white38 : Colors.white12);
    final bgColor = completed
        ? AppColors.accent.withValues(alpha: 0.15)
        : (unlocked
            ? AppColors.panel
            : AppColors.panel.withValues(alpha: 0.4));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded,
                  color: Colors.white38, size: 20)
            else if (completed)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 20)
            else
              const Icon(Icons.play_circle_rounded,
                  color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(
              'Lv ${config.levelNumber}',
              style: AppTextStyles.button(
                size: 17,
                color: unlocked ? AppColors.text : Colors.white38,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${config.targetBlocks} blocks',
              style: AppTextStyles.body(
                size: 11,
                color: unlocked ? Colors.white70 : Colors.white30,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: unlocked ? AppColors.accent : Colors.white24,
                  size: 11,
                ),
                const SizedBox(width: 2),
                Text(
                  '${config.coinReward}',
                  style: AppTextStyles.body(
                    size: 11,
                    color: unlocked ? AppColors.accent : Colors.white24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded,
              color: AppColors.text, size: 26),
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 6),
          Text('$coins', style: AppTextStyles.button(size: 16)),
        ],
      ),
    );
  }
}

