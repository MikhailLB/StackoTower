import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/stacko_assets.dart';
import '../game/achievements.dart';
import '../game/level_forge.dart';
import '../game/route_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/site_background.dart';
import '../widgets/ui_kit.dart';
import 'achievements_screen.dart';
import 'game_screen.dart';
import 'info_web_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'stats_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    progress.addListener(_onProgressChanged);
    AudioService.instance.playBgm(Bgm.menu);
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    progress.removeListener(_onProgressChanged);
    _fadeCtrl.dispose();
    super.dispose();
  }

  RouteLevel get _featured {
    for (final l in routeLevels) {
      if (!progress.isLevelCompleted(l.levelNumber)) return l;
    }
    return routeLevels.last;
  }

  Future<void> _push(Widget screen) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  Future<void> _openInfo(String title, String url) => _push(
        InfoWebScreen(title: title, url: url),
      );

  void _playDaily() {
    final now = DateTime.now();
    _push(GameScreen(level: LevelForge.daily(now), mode: GameMode.daily));
  }

  void _playEndless() {
    final stage = progress.endlessSolved;
    _push(GameScreen(
      level: LevelForge.endless(stage),
      mode: GameMode.endless,
      endlessStage: stage,
    ));
  }

  Future<void> _claimBonus() async {
    AudioService.instance.playSfx(Sfx.levelComplete);
    final amount = await progress.claimDailyBonus(DateTime.now());
    await syncAchievements(progress);
    if (!mounted || amount <= 0) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: NeonColors.cardFill,
        content: Text('Daily bonus: +$amount coins!',
            style: AppTextStyles.body()),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final total = routeLevels.length;
    final solved = progress.completedLevels.length;
    final featured = _featured;
    final now = DateTime.now();
    final bonusReady = progress.canClaimDailyBonus(now);
    final dailySolved = progress.isDailySolved(now);

    return Scaffold(
      body: Stack(
        children: [
          SiteBackground(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Top bar: settings / awards / stats + coins
                      Row(
                        children: [
                          CircleIconButton(
                              icon: Icons.settings_rounded,
                              onTap: () => _push(const SettingsScreen())),
                          const SizedBox(width: 8),
                          CircleIconButton(
                              icon: Icons.emoji_events_rounded,
                              onTap: () =>
                                  _push(const AchievementsScreen())),
                          const SizedBox(width: 8),
                          CircleIconButton(
                              icon: Icons.query_stats_rounded,
                              onTap: () => _push(const StatsScreen())),
                          const Spacer(),
                          CoinChip(coins: progress.coins),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Logo + tagline
                      Image.asset(StackoAssets.gameName,
                          width: size.width * 0.6, fit: BoxFit.contain),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: NeonColors.cardFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: NeonColors.cyan.withValues(alpha: 0.5)),
                        ),
                        child: Text('ONE-LINE ROUTE PUZZLE',
                            style: AppTextStyles.body(
                                    size: 11, color: NeonColors.cyan)
                                .copyWith(letterSpacing: 3)),
                      ),
                      const SizedBox(height: 10),
                      // Compact progress summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SummaryChip(
                            icon: Icons.flag_rounded,
                            label: '$solved/$total lots',
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            icon: Icons.star_rounded,
                            label: '${progress.totalStars} stars',
                          ),
                          if (progress.dailyStreak > 0) ...[
                            const SizedBox(width: 8),
                            _SummaryChip(
                              icon: Icons.local_fire_department_rounded,
                              label: '${progress.dailyStreak}d',
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      // Daily login bonus
                      if (bonusReady) ...[
                        NeonCard(
                          edge: NeonColors.cyan,
                          onTap: _claimBonus,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.card_giftcard_rounded,
                                  color: NeonColors.cyan, size: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Daily bonus ready: '
                                  '+${progress.nextDailyBonus(now)} coins',
                                  style: AppTextStyles.button(size: 14),
                                ),
                              ),
                              Text('CLAIM',
                                  style: AppTextStyles.button(
                                          size: 14, color: NeonColors.cyan)
                                      .copyWith(letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      // Featured "next lot" card
                      NeonCard(
                        edge: AppColors.accent,
                        onTap: () => _push(GameScreen(level: featured)),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            LotPreview(
                              rows: featured.rows,
                              cols: featured.cols,
                              box: 84,
                              walls: featured.walls,
                              startIndex: featured.startIndex,
                              exitIndex: featured.exitIndex,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    progress.isLevelCompleted(
                                            featured.levelNumber)
                                        ? 'REPLAY  ·  #${featured.levelNumber}'
                                        : 'NEXT LOT  ·  #${featured.levelNumber}',
                                    style: AppTextStyles.body(
                                            size: 10, color: AppColors.accent)
                                        .copyWith(letterSpacing: 2),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(featured.name,
                                      style: AppTextStyles.title(size: 20),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${districtOf(featured.levelNumber).name}'
                                      ' · ${featured.cols}×${featured.rows}',
                                      style: AppTextStyles.body(
                                          size: 12,
                                          color: AppColors.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.play_circle_fill_rounded,
                                          color: AppColors.accent, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Tap to pave',
                                          style: AppTextStyles.button(
                                              size: 13,
                                              color: AppColors.accent)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Daily + Endless modes
                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              icon: dailySolved
                                  ? Icons.check_circle_rounded
                                  : Icons.today_rounded,
                              title: 'Daily',
                              subtitle: dailySolved
                                  ? 'Solved today!'
                                  : 'New blueprint',
                              color: NeonColors.cyan,
                              onTap: _playDaily,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.all_inclusive_rounded,
                              title: 'Endless',
                              subtitle:
                                  '${progress.endlessSolved} shifts done',
                              color: NeonColors.violet,
                              onTap: _playEndless,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bottom action bar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: NeonTile(
                              icon: Icons.storefront_rounded,
                              label: 'Shop',
                              onTap: () => _push(const ShopScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: NeonTile(
                              icon: Icons.play_arrow_rounded,
                              label: 'PLAY',
                              featured: true,
                              onTap: () => _push(const LevelSelectScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NeonTile(
                              icon: Icons.help_outline_rounded,
                              label: 'How',
                              onTap: () {
                                AudioService.instance.playSfx(Sfx.buttonClick);
                                setState(() => _showHowTo = true);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LinkButton(
                              label: 'Privacy Policy',
                              onTap: () => _openInfo('Privacy Policy',
                                  'https://sttackotower.com/privacy-policy.html')),
                          const Text('·',
                              style: TextStyle(color: Colors.white38)),
                          _LinkButton(
                              label: 'Support',
                              onTap: () => _openInfo('Support',
                                  'https://sttackotower.com/support.html')),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showHowTo)
            HowToPlayOverlay(onClose: () => setState(() => _showHowTo = false)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: NeonColors.cardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.body(size: 12, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      edge: color,
      glow: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.button(size: 15)),
                Text(subtitle,
                    style: AppTextStyles.body(
                        size: 10, color: AppColors.textMuted),
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

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          label,
          style: AppTextStyles.body(size: 12, color: AppColors.textMuted)
              .copyWith(
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
