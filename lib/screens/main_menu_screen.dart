import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/stacko_assets.dart';
import '../game/route_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/site_background.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';
import 'info_web_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final total = routeLevels.length;
    final solved = progress.completedLevels.length;
    final featured = _featured;

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
                      // Top bar: settings + coins
                      Row(
                        children: [
                          CircleIconButton(
                              icon: Icons.settings_rounded,
                              onTap: () => _push(const SettingsScreen())),
                          const Spacer(),
                          CoinChip(coins: progress.coins),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Logo + tagline
                      Image.asset(StackoAssets.gameName,
                          width: size.width * 0.66, fit: BoxFit.contain),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      _ProgressTrack(solved: solved, total: total),
                      const Spacer(),
                      // Horizontal featured "next lot" card
                      NeonCard(
                        edge: AppColors.accent,
                        onTap: () => _push(GameScreen(level: featured)),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            LotPreview(
                              rows: featured.rows,
                              cols: featured.cols,
                              box: 92,
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
                                      style: AppTextStyles.title(size: 22),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('${featured.cols}×${featured.rows} lot',
                                      style: AppTextStyles.body(
                                          size: 13,
                                          color: AppColors.textMuted)),
                                  const SizedBox(height: 8),
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
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 6),
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

/// A row of level nodes connected like a route; solved nodes glow gold.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.solved, required this.total});
  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < total; i++)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: i < solved ? AppColors.accent : Colors.white12,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i < solved
                        ? AppColors.accent
                        : Colors.white24,
                    width: 1,
                  ),
                  boxShadow: i < solved
                      ? [
                          BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.6),
                              blurRadius: 6)
                        ]
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text('$solved / $total lots paved',
            style: AppTextStyles.body(size: 12, color: AppColors.textMuted)),
      ],
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
