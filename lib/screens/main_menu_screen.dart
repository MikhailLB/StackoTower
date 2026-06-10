import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/skyline.dart';
import '../game/campaign.dart';
import '../game/tower_engine.dart';
import '../main.dart';
import 'achievements_screen.dart';
import 'campaign_screen.dart';
import 'how_to_play_screen.dart';
import 'lore_screen.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'stats_screen.dart';
import 'story_intro_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    progress.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRunFlow());
  }

  Future<void> _firstRunFlow() async {
    if (!progress.storySeen) {
      await progress.setStorySeen();
      if (!mounted) return;
      await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const StoryIntroScreen()));
    }
    await _maybeBonus();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    progress.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _maybeBonus() async {
    final now = DateTime.now();
    if (!progress.canClaimDailyBonus(now)) return;
    final amount = await progress.claimDailyBonus(now);
    if (amount <= 0 || !mounted) return;
    _toast('Daily bonus: +$amount coins  (streak ${progress.bonusStreak})');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: Sky.label(size: 14)),
      backgroundColor: Sky.panel,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _go(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dailyDone = progress.isDailySolved(now);
    return Scaffold(
      body: SkyBackdrop(
        glowColor: Sky.violet,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _topBar(),
                const Spacer(),
                Text('STACKO', style: Sky.display(size: 52)),
                Text('TOWER',
                    style: Sky.display(size: 52, color: Sky.cyan)
                        .copyWith(letterSpacing: 10)),
                const SizedBox(height: 6),
                Text('BALANCE THE SKYLINE',
                    style: Sky.body(size: 14, color: Sky.magenta)),
                const Spacer(),
                _primary('ENDLESS CLIMB', Icons.all_inclusive_rounded, Sky.cyan,
                    () => _go(const PlayScreen(mode: GameMode.endless))),
                const SizedBox(height: 12),
                _primary('CAMPAIGN', Icons.location_city_rounded, Sky.violet,
                    () => _go(const CampaignScreen())),
                const SizedBox(height: 12),
                _primary(
                  dailyDone ? 'DAILY · DONE' : 'DAILY TOWER',
                  Icons.today_rounded,
                  dailyDone ? Sky.muted : Sky.lime,
                  () => _go(PlayScreen(mode: GameMode.daily, seed: dailySeed(now))),
                ),
                const SizedBox(height: 20),
                _navRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _coin(),
        const Spacer(),
        _miniStat(Icons.emoji_events_rounded, '${progress.highScore}', Sky.amber),
        const SizedBox(width: 10),
        _miniStat(Icons.star_rounded, '${progress.totalStars}', Sky.lime),
      ],
    );
  }

  Widget _coin() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Sky.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Sky.amber.withValues(alpha: 0.5), width: 1.4),
        boxShadow: Sky.glow(Sky.amber, blur: 10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monetization_on_rounded, color: Sky.amber, size: 20),
        const SizedBox(width: 6),
        Text('${progress.coins}', style: Sky.number(size: 16)),
      ]),
    );
  }

  Widget _miniStat(IconData icon, String v, Color c) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: 18),
      const SizedBox(width: 4),
      Text(v, style: Sky.number(size: 15)),
    ]);
  }

  Widget _primary(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.7), width: 1.6),
          boxShadow: Sky.glow(color, blur: 16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Text(label, style: Sky.label(size: 20, spacing: 1.6)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _navRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 12,
      children: [
        _navIcon(Icons.storefront_rounded, 'Shop', () => _go(const ShopScreen())),
        _navIcon(Icons.military_tech_rounded, 'Awards',
            () => _go(const AchievementsScreen())),
        _navIcon(Icons.auto_stories_rounded, 'Story', () => _go(const LoreScreen())),
        _navIcon(Icons.bar_chart_rounded, 'Stats', () => _go(const StatsScreen())),
        _navIcon(Icons.help_outline_rounded, 'How', () => _go(const HowToPlayScreen())),
        _navIcon(Icons.settings_rounded, 'Settings',
            () => _go(const SettingsScreen())),
      ],
    );
  }

  Widget _navIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Sky.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Sky.violet.withValues(alpha: 0.5), width: 1.4),
            ),
            child: Icon(icon, color: Sky.text, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Sky.body(size: 12)),
        ],
      ),
    );
  }
}
