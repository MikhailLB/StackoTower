import 'package:flutter/material.dart';

import '../state/game_progress.dart';
import 'route_level.dart';

/// A single site-license award. [progressOf] returns (current, target) so the
/// awards screen can render progress bars; the award unlocks at current >=
/// target and pays out [coinReward] once.
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
    id: 'first_steps',
    title: 'First Shovel',
    description: 'Pave your first lot.',
    icon: Icons.flag_rounded,
    coinReward: 50,
    progressOf: (p) => (p.completedLevels.length, 1),
  ),
  Achievement(
    id: 'apprentice',
    title: 'Apprentice Paver',
    description: 'Complete 5 campaign lots.',
    icon: Icons.handyman_rounded,
    coinReward: 75,
    progressOf: (p) => (p.completedLevels.length, 5),
  ),
  Achievement(
    id: 'foreman',
    title: 'Site Foreman',
    description: 'Complete 15 campaign lots.',
    icon: Icons.engineering_rounded,
    coinReward: 150,
    progressOf: (p) => (p.completedLevels.length, 15),
  ),
  Achievement(
    id: 'architect',
    title: 'City Architect',
    description: 'Complete 30 campaign lots.',
    icon: Icons.apartment_rounded,
    coinReward: 300,
    progressOf: (p) => (p.completedLevels.length, 30),
  ),
  Achievement(
    id: 'urban_planner',
    title: 'Urban Planner',
    description: 'Complete 45 campaign lots.',
    icon: Icons.location_city_rounded,
    coinReward: 450,
    progressOf: (p) => (p.completedLevels.length, 45),
  ),
  Achievement(
    id: 'city_legend',
    title: 'City Legend',
    description: 'Complete all 60 campaign lots.',
    icon: Icons.emoji_events_rounded,
    coinReward: 1000,
    progressOf: (p) => (p.completedLevels.length, routeLevels.length),
  ),
  Achievement(
    id: 'perfect_run',
    title: 'Flawless Blueprint',
    description: 'Earn your first 3-star clear.',
    icon: Icons.auto_awesome_rounded,
    coinReward: 100,
    progressOf: (p) => (p.statPerfect, 1),
  ),
  Achievement(
    id: 'star_collector',
    title: 'Star Collector',
    description: 'Collect 45 stars.',
    icon: Icons.star_rounded,
    coinReward: 200,
    progressOf: (p) => (p.totalStars, 45),
  ),
  Achievement(
    id: 'star_master',
    title: 'Star Master',
    description: 'Collect 100 stars.',
    icon: Icons.stars_rounded,
    coinReward: 400,
    progressOf: (p) => (p.totalStars, 100),
  ),
  Achievement(
    id: 'star_god',
    title: 'Constellation',
    description: 'Collect every star in the campaign.',
    icon: Icons.workspace_premium_rounded,
    coinReward: 1500,
    progressOf: (p) => (p.totalStars, routeLevels.length * 3),
  ),
  Achievement(
    id: 'endless_starter',
    title: 'Night Shift',
    description: 'Clear 5 lots in Endless Shift.',
    icon: Icons.all_inclusive_rounded,
    coinReward: 100,
    progressOf: (p) => (p.endlessSolved, 5),
  ),
  Achievement(
    id: 'endless_pro',
    title: 'Overtime Hero',
    description: 'Clear 25 lots in Endless Shift.',
    icon: Icons.bolt_rounded,
    coinReward: 300,
    progressOf: (p) => (p.endlessSolved, 25),
  ),
  Achievement(
    id: 'endless_streak',
    title: 'Hot Streak',
    description: 'Reach a 10-lot streak in one Endless run.',
    icon: Icons.local_fire_department_rounded,
    coinReward: 250,
    progressOf: (p) => (p.endlessBestStreak, 10),
  ),
  Achievement(
    id: 'daily_first',
    title: 'Fresh Blueprint',
    description: 'Solve your first Daily Blueprint.',
    icon: Icons.today_rounded,
    coinReward: 100,
    progressOf: (p) => (p.dailySolvedTotal, 1),
  ),
  Achievement(
    id: 'daily_week',
    title: 'Reliable Contractor',
    description: 'Hold a 7-day Daily Blueprint streak.',
    icon: Icons.calendar_month_rounded,
    coinReward: 350,
    progressOf: (p) => (p.dailyStreak, 7),
  ),
  Achievement(
    id: 'shopaholic',
    title: 'New Look',
    description: 'Buy your first block skin.',
    icon: Icons.shopping_bag_rounded,
    coinReward: 50,
    progressOf: (p) => (p.ownedSkins.length, 2),
  ),
  Achievement(
    id: 'collector',
    title: 'Full Wardrobe',
    description: 'Own all 6 block skins.',
    icon: Icons.checkroom_rounded,
    coinReward: 500,
    progressOf: (p) => (p.ownedSkins.length, 6),
  ),
  Achievement(
    id: 'stylist',
    title: 'Road Stylist',
    description: 'Own all road themes.',
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
    title: 'Paving Tycoon',
    description: 'Earn 15,000 coins in total.',
    icon: Icons.account_balance_rounded,
    coinReward: 600,
    progressOf: (p) => (p.statCoinsEarned, 15000),
  ),
  Achievement(
    id: 'paver_500',
    title: 'Plot by Plot',
    description: 'Pave 500 plots in total.',
    icon: Icons.grid_on_rounded,
    coinReward: 150,
    progressOf: (p) => (p.statPlotsPaved, 500),
  ),
  Achievement(
    id: 'paver_5000',
    title: 'Asphalt River',
    description: 'Pave 5,000 plots in total.',
    icon: Icons.waves_rounded,
    coinReward: 500,
    progressOf: (p) => (p.statPlotsPaved, 5000),
  ),
  Achievement(
    id: 'comeback',
    title: 'Second Thoughts',
    description: 'Use Undo 100 times.',
    icon: Icons.undo_rounded,
    coinReward: 100,
    progressOf: (p) => (p.statUndos, 100),
  ),
  Achievement(
    id: 'booster',
    title: 'Work Smarter',
    description: 'Use your first power-up.',
    icon: Icons.rocket_launch_rounded,
    coinReward: 50,
    progressOf: (p) => (p.statBoostsUsed, 1),
  ),
];

/// Checks every award against the current progress, unlocks the newly met
/// ones (paying their coin rewards) and returns them so the UI can toast.
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
