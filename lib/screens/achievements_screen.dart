import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/achievements.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/site_background.dart';
import '../widgets/ui_kit.dart';

/// Site Licenses — the award wall. Locked awards show live progress bars.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    progress.addListener(_onChanged);
    // Catch up on anything earned outside a round (e.g. coin milestones).
    syncAchievements(progress);
  }

  @override
  void dispose() {
    progress.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unlocked =
        allAchievements.where((a) => progress.hasAchievement(a.id)).length;

    return Scaffold(
      body: SiteBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
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
                          Text('SITE LICENSES',
                              style: AppTextStyles.body(
                                      size: 10, color: NeonColors.cyan)
                                  .copyWith(letterSpacing: 3)),
                          Text('Awards', style: AppTextStyles.title(size: 26)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: NeonColors.cardFill,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      child: Text('$unlocked/${allAchievements.length}',
                          style: AppTextStyles.button(size: 16)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: allAchievements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final a = allAchievements[index];
                    return _AwardCard(
                      achievement: a,
                      unlocked: progress.hasAchievement(a.id),
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
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final (current, target) = achievement.progressOf(progress);
    final ratio = target == 0 ? 1.0 : (current / target).clamp(0.0, 1.0);
    final edge = unlocked ? AppColors.accent : NeonColors.violet;

    return NeonCard(
      edge: edge,
      glow: unlocked,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.accent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unlocked ? AppColors.accent : Colors.white24,
              ),
            ),
            child: Icon(
              achievement.icon,
              color: unlocked ? AppColors.accent : Colors.white38,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: AppTextStyles.button(
                          size: 16,
                          color: unlocked ? AppColors.text : Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.monetization_on_rounded,
                        color: unlocked ? AppColors.accent : Colors.white38,
                        size: 14),
                    const SizedBox(width: 3),
                    Text('${achievement.coinReward}',
                        style: AppTextStyles.button(
                          size: 13,
                          color: unlocked ? AppColors.accent : Colors.white38,
                        )),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: AppTextStyles.body(
                      size: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                if (unlocked)
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.accent, size: 15),
                      const SizedBox(width: 5),
                      Text('Unlocked',
                          style: AppTextStyles.button(
                              size: 12, color: AppColors.accent)),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                NeonColors.cyan),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$current/$target',
                        style: AppTextStyles.body(
                            size: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
