import 'package:flutter/material.dart';

import '../state/game_progress.dart';
import 'campaign.dart';

/// A single award. [progressOf] returns (current, target) for progress bars;
/// it unlocks at current >= target and pays [coinReward] once.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.coinReward,
    required this.progressOf,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int coinReward;
  final (int, int) Function(GameProgress p) progressOf;

  bool isMet(GameProgress p) {
    final (current, target) = progressOf(p);
    return current >= target;
  }
}

final List<Achievement> allAchievements = [
  Achievement(
    id: 'first_floor',
    title: 'Groundbreaker',
    description: 'Stack your first tower.',
    icon: Icons.flag_rounded,
    coinReward: 50,
    progressOf: (p) => (p.statCompletes, 1),
  ),
  Achievement(
    id: 'height_25',
    title: 'High Riser',
    description: 'Reach a height of 25 in one run.',
    icon: Icons.trending_up_rounded,
    coinReward: 100,
    progressOf: (p) => (p.highScore, 25),
  ),
  Achievement(
    id: 'height_50',
    title: 'Skyscraper',
    description: 'Reach a height of 50 in one run.',
    icon: Icons.apartment_rounded,
    coinReward: 250,
    progressOf: (p) => (p.highScore, 50),
  ),
  Achievement(
    id: 'height_100',
    title: 'Cloud Piercer',
    description: 'Reach a height of 100 in one run.',
    icon: Icons.filter_drama_rounded,
    coinReward: 600,
    progressOf: (p) => (p.highScore, 100),
  ),
  Achievement(
    id: 'campaign_5',
    title: 'Contractor',
    description: 'Clear 5 campaign floors.',
    icon: Icons.handyman_rounded,
    coinReward: 100,
    progressOf: (p) => (p.completedLevels.length, 5),
  ),
  Achievement(
    id: 'campaign_20',
    title: 'Site Foreman',
    description: 'Clear 20 campaign floors.',
    icon: Icons.engineering_rounded,
    coinReward: 250,
    progressOf: (p) => (p.completedLevels.length, 20),
  ),
  Achievement(
    id: 'campaign_all',
    title: 'Master Builder',
    description: 'Clear every campaign floor.',
    icon: Icons.emoji_events_rounded,
    coinReward: 1200,
    progressOf: (p) => (p.completedLevels.length, campaignCount),
  ),
  Achievement(
    id: 'boss_first',
    title: 'Giant Slayer',
    description: 'Defeat your first boss floor.',
    icon: Icons.shield_rounded,
    coinReward: 200,
    progressOf: (p) => (p.bossesBeaten, 1),
  ),
  Achievement(
    id: 'boss_all',
    title: 'Apex Predator',
    description: 'Defeat all 12 district bosses.',
    icon: Icons.whatshot_rounded,
    coinReward: 2000,
    progressOf: (p) => (p.bossesBeaten, 12),
  ),
  Achievement(
    id: 'stars_30',
    title: 'Star Rigger',
    description: 'Collect 30 stars.',
    icon: Icons.star_rounded,
    coinReward: 200,
    progressOf: (p) => (p.totalStars, 30),
  ),
  Achievement(
    id: 'stars_all',
    title: 'Constellation',
    description: 'Earn every campaign star.',
    icon: Icons.workspace_premium_rounded,
    coinReward: 1500,
    progressOf: (p) => (p.totalStars, campaignCount * 3),
  ),
  Achievement(
    id: 'combo_10',
    title: 'Steady Hands',
    description: 'Hit a 10× balance combo.',
    icon: Icons.local_fire_department_rounded,
    coinReward: 250,
    progressOf: (p) => (p.endlessBestStreak, 10),
  ),
  Achievement(
    id: 'combo_25',
    title: 'Master of Balance',
    description: 'Hit a 25× balance combo.',
    icon: Icons.bolt_rounded,
    coinReward: 500,
    progressOf: (p) => (p.endlessBestStreak, 25),
  ),
  Achievement(
    id: 'endless_10',
    title: 'Night Shift',
    description: 'Play 10 Endless runs.',
    icon: Icons.all_inclusive_rounded,
    coinReward: 150,
    progressOf: (p) => (p.endlessSolved, 10),
  ),
  Achievement(
    id: 'daily_first',
    title: 'Fresh Skyline',
    description: 'Finish your first Daily Tower.',
    icon: Icons.today_rounded,
    coinReward: 100,
    progressOf: (p) => (p.dailySolvedTotal, 1),
  ),
  Achievement(
    id: 'daily_week',
    title: 'Reliable Crew',
    description: 'Hold a 7-day Daily streak.',
    icon: Icons.calendar_month_rounded,
    coinReward: 350,
    progressOf: (p) => (p.dailyStreak, 7),
  ),
  Achievement(
    id: 'perfect_25',
    title: 'Precision Crane',
    description: 'Land 25 perfect blocks in total.',
    icon: Icons.center_focus_strong_rounded,
    coinReward: 200,
    progressOf: (p) => (p.statPlotsPaved, 25),
  ),
  Achievement(
    id: 'stylist',
    title: 'Skyline Stylist',
    description: 'Own all 6 tower skins.',
    icon: Icons.palette_rounded,
    coinReward: 400,
    progressOf: (p) => (p.ownedThemes.length, 6),
  ),
  Achievement(
    id: 'rich',
    title: 'Coin Vault',
    description: 'Hold 2,000 coins at once.',
    icon: Icons.savings_rounded,
    coinReward: 200,
    progressOf: (p) => (p.coins, 2000),
  ),
  Achievement(
    id: 'tycoon',
    title: 'Tower Tycoon',
    description: 'Earn 15,000 coins in total.',
    icon: Icons.account_balance_rounded,
    coinReward: 600,
    progressOf: (p) => (p.statCoinsEarned, 15000),
  ),
];

/// Unlocks newly-met awards (paying rewards) and returns them for toasting.
Future<List<Achievement>> syncAchievements(GameProgress progress) async {
  final unlocked = <Achievement>[];
  for (final a in allAchievements) {
    if (progress.hasAchievement(a.id) || !a.isMet(progress)) continue;
    await progress.unlockAchievement(a.id);
    await progress.addCoins(a.coinReward);
    unlocked.add(a);
  }
  return unlocked;
}
