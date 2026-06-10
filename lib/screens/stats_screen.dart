import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/achievements.dart';
import '../game/campaign.dart';
import '../main.dart';
import '../widgets/site_background.dart';
import '../widgets/ui_kit.dart';

/// Crew Records — lifetime player statistics and rank.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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

  static const List<(int, String)> _ranks = [
    (0, 'Trainee'),
    (5, 'Paver'),
    (15, 'Crew Lead'),
    (30, 'Foreman'),
    (45, 'Site Manager'),
    (60, 'City Builder'),
  ];

  String get _rank {
    final solved = progress.completedLevels.length;
    var rank = _ranks.first.$2;
    for (final (need, name) in _ranks) {
      if (solved >= need) rank = name;
    }
    return rank;
  }

  String _playTime() {
    final s = progress.statPlaySeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final solved = progress.completedLevels.length;
    final total = campaignCount;
    final awards =
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
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CREW RECORDS',
                              style: AppTextStyles.body(
                                      size: 10, color: NeonColors.cyan)
                                  .copyWith(letterSpacing: 3)),
                          Text('Statistics',
                              style: AppTextStyles.title(size: 26)),
                        ],
                      ),
                    ),
                    CoinChip(coins: progress.coins),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Rank banner
                    NeonCard(
                      edge: AppColors.accent,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: const Icon(Icons.military_tech_rounded,
                                color: AppColors.accent, size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CURRENT RANK',
                                    style: AppTextStyles.body(
                                            size: 10,
                                            color: AppColors.textMuted)
                                        .copyWith(letterSpacing: 2)),
                                Text(_rank,
                                    style: AppTextStyles.title(size: 24)),
                                Text('$solved/$total lots paved',
                                    style: AppTextStyles.body(
                                        size: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Campaign'),
                    const SizedBox(height: 10),
                    _StatGrid(items: [
                      ('Lots paved', '$solved', Icons.flag_rounded),
                      (
                        'Stars earned',
                        '${progress.totalStars}/${total * 3}',
                        Icons.star_rounded
                      ),
                      (
                        'Perfect clears',
                        '${progress.statPerfect}',
                        Icons.auto_awesome_rounded
                      ),
                      (
                        'Awards',
                        '$awards/${allAchievements.length}',
                        Icons.emoji_events_rounded
                      ),
                    ]),
                    const SizedBox(height: 20),
                    const SectionLabel('Daily & Endless'),
                    const SizedBox(height: 10),
                    _StatGrid(items: [
                      (
                        'Daily streak',
                        '${progress.dailyStreak}',
                        Icons.local_fire_department_rounded
                      ),
                      (
                        'Dailies solved',
                        '${progress.dailySolvedTotal}',
                        Icons.today_rounded
                      ),
                      (
                        'Endless cleared',
                        '${progress.endlessSolved}',
                        Icons.all_inclusive_rounded
                      ),
                      (
                        'Best streak',
                        '${progress.endlessBestStreak}',
                        Icons.bolt_rounded
                      ),
                    ]),
                    const SizedBox(height: 20),
                    const SectionLabel('Lifetime'),
                    const SizedBox(height: 10),
                    _StatGrid(items: [
                      (
                        'Plots paved',
                        '${progress.statPlotsPaved}',
                        Icons.grid_on_rounded
                      ),
                      (
                        'Coins earned',
                        '${progress.statCoinsEarned}',
                        Icons.monetization_on_rounded
                      ),
                      ('Time on site', _playTime(), Icons.schedule_rounded),
                      (
                        'Undos used',
                        '${progress.statUndos}',
                        Icons.undo_rounded
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<(String, String, IconData)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: _StatTile(item: items[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < items.length
                      ? _StatTile(item: items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final (String, String, IconData) item;

  @override
  Widget build(BuildContext context) {
    final (label, value, icon) = item;
    return NeonCard(
      glow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: NeonColors.cyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.button(size: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: AppTextStyles.body(
                        size: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
