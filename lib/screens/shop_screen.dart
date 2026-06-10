import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/skyline.dart';
import '../game/achievements.dart';
import '../game/road_themes.dart';
import '../main.dart';
import '../state/game_progress.dart';

/// Spend coins on tower skins and consumable balance boosts.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _stabilisePrice = 90;
  static const _slowPrice = 70;
  static const _widenPrice = 110;
  static const _doublePrice = 80;
  static const _luckyPrice = 30;

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

  Future<void> _buyTheme(RoadTheme t) async {
    if (progress.ownedThemes.contains(t.id)) {
      await progress.setSelectedTheme(t.id);
      return;
    }
    if (!await progress.spendCoins(t.price)) {
      _snack('Not enough coins');
      return;
    }
    await progress.unlockTheme(t.id);
    await progress.setSelectedTheme(t.id);
    await syncAchievements(progress);
  }

  Future<void> _buyBoost(int price, Future<void> Function(int) grant) async {
    if (!await progress.spendCoins(price)) {
      _snack('Not enough coins');
      return;
    }
    await grant(1);
  }

  Future<void> _buyUpgrade(String id) async {
    if (progress.upgradeLevel(id) >= GameProgress.upMaxLevel) return;
    if (!await progress.buyUpgrade(id)) _snack('Not enough coins');
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: Sky.panel,
        behavior: SnackBarBehavior.floating,
        content: Text(text, style: Sky.label(size: 14)),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackdrop(
        glowColor: Sky.amber,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    _back(),
                    const SizedBox(width: 12),
                    Text('SHOP', style: Sky.display(size: 24)),
                    const Spacer(),
                    _coin(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _label('Tower Skins'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                      children: [
                        for (final t in roadThemes)
                          _SkinCard(
                            theme: t,
                            owned: progress.ownedThemes.contains(t.id),
                            selected: progress.selectedTheme == t.id,
                            onTap: () => _buyTheme(t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _label('Crane Upgrades'),
                    const SizedBox(height: 12),
                    _UpgradeCard(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Wide Base',
                      subtitle: 'Permanently widens your starting footing.',
                      id: 'base',
                      accent: Sky.cyan,
                      onBuy: () => _buyUpgrade('base'),
                    ),
                    const SizedBox(height: 10),
                    _UpgradeCard(
                      icon: Icons.speed_rounded,
                      title: 'Steady Crane',
                      subtitle: 'Permanently slows the swing — easier aiming.',
                      id: 'steady',
                      accent: Sky.violet,
                      onBuy: () => _buyUpgrade('steady'),
                    ),
                    const SizedBox(height: 10),
                    _UpgradeCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Payout',
                      subtitle: 'Permanently boosts coins earned per run.',
                      id: 'payout',
                      accent: Sky.amber,
                      onBuy: () => _buyUpgrade('payout'),
                    ),
                    const SizedBox(height: 24),
                    _label('Balance Boosts'),
                    const SizedBox(height: 12),
                    _PowerCard(
                      icon: Icons.balance_rounded,
                      title: 'Stabiliser',
                      subtitle: 'Cancels wind & recovers a dangerous lean.',
                      price: _stabilisePrice,
                      owned: progress.skipBoosts,
                      accent: Sky.lime,
                      onBuy: () => _buyBoost(_stabilisePrice, progress.grantSkip),
                    ),
                    const SizedBox(height: 10),
                    _PowerCard(
                      icon: Icons.slow_motion_video_rounded,
                      title: 'Slow-Mo',
                      subtitle: 'Slows the crane for 5 seconds — line up the shot.',
                      price: _slowPrice,
                      owned: progress.slowBoosts,
                      accent: Sky.cyan,
                      onBuy: () => _buyBoost(_slowPrice, progress.grantSlow),
                    ),
                    const SizedBox(height: 10),
                    _PowerCard(
                      icon: Icons.open_in_full_rounded,
                      title: 'Reinforce',
                      subtitle: 'Widens the support back toward a full base.',
                      price: _widenPrice,
                      owned: progress.widenBoosts,
                      accent: Sky.violet,
                      onBuy: () => _buyBoost(_widenPrice, progress.grantWiden),
                    ),
                    const SizedBox(height: 10),
                    _PowerCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Double Coins',
                      subtitle: 'Doubles coin rewards for your next run.',
                      price: _doublePrice,
                      owned: progress.doubleCoinsBoosts,
                      accent: Sky.amber,
                      onBuy: () => _buyBoost(_doublePrice, progress.grantDoubleCoins),
                    ),
                    const SizedBox(height: 10),
                    _PowerCard(
                      icon: Icons.casino_rounded,
                      title: 'Lucky Bonus',
                      subtitle: '+50 bonus coins on your next run.',
                      price: _luckyPrice,
                      owned: progress.luckyBoosts,
                      accent: Sky.magenta,
                      onBuy: () => _buyBoost(_luckyPrice, progress.grantLucky),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Row(children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Sky.cyan,
            borderRadius: BorderRadius.circular(2),
            boxShadow: Sky.glow(Sky.cyan, blur: 8),
          ),
        ),
        const SizedBox(width: 10),
        Text(t.toUpperCase(), style: Sky.label(size: 16, spacing: 1.5)),
      ]);

  Widget _coin() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Sky.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Sky.amber.withValues(alpha: 0.5), width: 1.4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on_rounded, color: Sky.amber, size: 20),
          const SizedBox(width: 6),
          Text('${progress.coins}', style: Sky.number(size: 16)),
        ]),
      );

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

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.theme,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  final RoadTheme theme;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final edge = selected ? Sky.amber : (owned ? Sky.cyan : Sky.violet);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Sky.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: edge.withValues(alpha: 0.6), width: 1.5),
          boxShadow: selected ? Sky.glow(edge, blur: 12) : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        width: 40 - i * 6,
                        height: 9,
                        decoration: BoxDecoration(
                          color: theme.color,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                                color: theme.glow.withValues(alpha: 0.7),
                                blurRadius: 8),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(theme.name,
                style: Sky.label(size: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            if (selected)
              Text('ACTIVE', style: Sky.body(size: 11, color: Sky.amber))
            else if (owned)
              Text('OWNED', style: Sky.body(size: 11, color: Sky.cyan))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: Sky.amber, size: 12),
                  const SizedBox(width: 3),
                  Text('${theme.price}', style: Sky.number(size: 13)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.id,
    required this.accent,
    required this.onBuy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String id;
  final Color accent;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final level = progress.upgradeLevel(id);
    final maxed = level >= GameProgress.upMaxLevel;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Sky.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Sky.label(size: 16)),
                const SizedBox(height: 3),
                Text(subtitle, style: Sky.body(size: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < GameProgress.upMaxLevel; i++)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 16,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < level ? accent : Sky.panelDeep,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: maxed ? null : onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: maxed ? Sky.panelDeep : accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: maxed ? null : Sky.glow(accent, blur: 10),
              ),
              child: maxed
                  ? Text('MAX', style: Sky.label(size: 13, color: Sky.muted))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: Sky.bg0, size: 15),
                      const SizedBox(width: 4),
                      Text('${progress.upgradePrice(id)}',
                          style: Sky.label(size: 14, color: Sky.bg0)),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.owned,
    required this.accent,
    required this.onBuy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int price;
  final int owned;
  final Color accent;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Sky.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: Sky.label(size: 16)),
                    if (owned > 0) ...[
                      const SizedBox(width: 8),
                      Text('×$owned', style: Sky.body(size: 13, color: accent)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Sky.body(size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: Sky.glow(accent, blur: 10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Sky.bg0, size: 15),
                const SizedBox(width: 4),
                Text('$price', style: Sky.label(size: 14, color: Sky.bg0)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
