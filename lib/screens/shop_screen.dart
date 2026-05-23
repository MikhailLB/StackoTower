import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/stacko_assets.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';

/// Spend earned coins on cosmetic block skins or consumable boosts.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const Map<int, int> _skinPrices = {1: 10, 2: 100, 3: 500};
  static const int _firstComingSoonSkin = 4;

  // Boost prices
  static const _slowHookPrice = 35;
  static const _secondChancePrice = 60;
  static const _doubleCoinsPrice = 80;
  static const _ghostBlockPrice = 45;
  static const _speedFreezePrice = 70;
  static const _wideBasePrice = 55;
  static const _luckyPrice = 30;

  bool _isComingSoon(int skin) => skin >= _firstComingSoonSkin;
  int? _priceOf(int skin) => _skinPrices[skin];

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

  Future<void> _buySkin(int skin) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (_isComingSoon(skin)) {
      _showSnack('Coming soon!');
      return;
    }
    if (progress.ownedSkins.contains(skin)) {
      await progress.setSelectedSkin(skin);
      return;
    }
    final price = _priceOf(skin);
    if (price == null) return;
    final ok = await progress.spendCoins(price);
    if (!ok) {
      _showSnack('Not enough coins');
      return;
    }
    await progress.unlockSkin(skin);
    await progress.setSelectedSkin(0);
  }

  Future<void> _buyBoost(
    int price,
    Future<void> Function(int) grant,
  ) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    final ok = await progress.spendCoins(price);
    if (!ok) {
      _showSnack('Not enough coins');
      return;
    }
    await grant(1);
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.panel,
        content: Text(text, style: AppTextStyles.body()),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(StackoAssets.startBg, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
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
                          'Shop',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title(size: 34),
                        ),
                      ),
                      _CoinPill(coins: progress.coins),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        // --- Skins ---
                        _SectionHeader(title: 'Block Skins'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: size.shortestSide * 0.28,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 6,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, index) {
                              final skin = index + 1;
                              final owned =
                                  progress.ownedSkins.contains(skin);
                              final selected =
                                  progress.selectedSkin == skin;
                              final comingSoon = _isComingSoon(skin);
                              return _SkinCard(
                                skin: skin,
                                owned: owned,
                                selected: selected,
                                price: _priceOf(skin),
                                comingSoon: comingSoon,
                                onTap: () => _buySkin(skin),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ToggleChoice(
                          selected: progress.selectedSkin == 0,
                          onTap: () {
                            AudioService.instance.playSfx(Sfx.buttonClick);
                            progress.setSelectedSkin(0);
                          },
                        ),

                        const SizedBox(height: 22),
                        // --- Boosts ---
                        _SectionHeader(title: 'Boosts'),
                        const SizedBox(height: 8),
                        _BoostCard(
                          icon: Icons.speed_rounded,
                          title: 'Slow Hook',
                          subtitle:
                              'Slows the hook for 6 seconds at round start.',
                          price: _slowHookPrice,
                          owned: progress.slowHookBoosts,
                          onBuy: () => _buyBoost(
                              _slowHookPrice, progress.grantSlowHook),
                        ),
                        const SizedBox(height: 8),
                        _BoostCard(
                          icon: Icons.favorite_rounded,
                          title: 'Second Chance',
                          subtitle:
                              'Survive one bad drop and keep playing.',
                          price: _secondChancePrice,
                          owned: progress.secondChanceBoosts,
                          onBuy: () => _buyBoost(
                              _secondChancePrice,
                              progress.grantSecondChance),
                        ),
                        const SizedBox(height: 8),
                        _BoostCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Double Coins',
                          subtitle:
                              'Doubles coin rewards for your next game.',
                          price: _doubleCoinsPrice,
                          owned: progress.doubleCoinsBoosts,
                          onBuy: () => _buyBoost(
                              _doubleCoinsPrice,
                              progress.grantDoubleCoins),
                        ),
                        const SizedBox(height: 8),
                        _BoostCard(
                          icon: Icons.blur_on_rounded,
                          title: 'Ghost Block',
                          subtitle:
                              'One bad placement is silently forgiven per game.',
                          price: _ghostBlockPrice,
                          owned: progress.ghostBlockBoosts,
                          onBuy: () => _buyBoost(
                              _ghostBlockPrice, progress.grantGhostBlock),
                        ),
                        const SizedBox(height: 8),
                        _BoostCard(
                          icon: Icons.ac_unit_rounded,
                          title: 'Speed Freeze',
                          subtitle:
                              'Hook speed stays constant for the first 10 blocks.',
                          price: _speedFreezePrice,
                          owned: progress.speedFreezeBoosts,
                          onBuy: () => _buyBoost(
                              _speedFreezePrice,
                              progress.grantSpeedFreeze),
                        ),
                        const SizedBox(height: 8),
                        _BoostCard(
                          icon: Icons.open_with_rounded,
                          title: 'Wide Base',
                          subtitle:
                              'Halves the overlap requirement for the first 3 blocks.',
                          price: _wideBasePrice,
                          owned: progress.wideBaseBoosts,
                          onBuy: () => _buyBoost(
                              _wideBasePrice, progress.grantWideBase),
                        ),
                        const SizedBox(height: 8),
                        _BoostCard(
                          icon: Icons.casino_rounded,
                          title: 'Lucky Boost',
                          subtitle:
                              '+20 bonus coins when you complete a level.',
                          price: _luckyPrice,
                          owned: progress.luckyBoosts,
                          onBuy: () =>
                              _buyBoost(_luckyPrice, progress.grantLucky),
                        ),
                        const SizedBox(height: 24),
                      ],
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
              color: AppColors.accent, size: 22),
          const SizedBox(width: 6),
          Text('$coins', style: AppTextStyles.button(size: 18)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: AppTextStyles.button(size: 20)),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.selected,
    required this.price,
    required this.comingSoon,
    required this.onTap,
  });

  final int skin;
  final bool owned;
  final bool selected;
  final int? price;
  final bool comingSoon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.accent
        : (owned
            ? Colors.white60
            : (comingSoon ? Colors.white24 : Colors.black54));
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2.5),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: comingSoon ? 0.35 : 1,
                    child: Image.asset(
                      StackoAssets.block(skin),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (comingSoon)
                  Text(
                    'Soon',
                    style: AppTextStyles.body(
                        size: 11, color: Colors.white70),
                    textAlign: TextAlign.center,
                  )
                else if (owned)
                  Text(
                    selected ? 'Active' : 'Owned',
                    style: AppTextStyles.body(
                        size: 11, color: AppColors.accent),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: AppColors.accent, size: 13),
                      const SizedBox(width: 2),
                      Text('${price ?? 0}',
                          style: AppTextStyles.body(size: 11)),
                    ],
                  ),
              ],
            ),
          ),
          if (comingSoon)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: Colors.white70, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleChoice extends StatelessWidget {
  const _ToggleChoice({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shuffle_rounded,
                color: AppColors.text, size: 18),
            const SizedBox(width: 8),
            Text(
              'Random Skin',
              style: AppTextStyles.body(
                size: 14,
                color: selected ? AppColors.textDark : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoostCard extends StatelessWidget {
  const _BoostCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.owned,
    required this.onBuy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int price;
  final int owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTextStyles.button(size: 16)),
                    const SizedBox(width: 6),
                    if (owned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'x$owned',
                          style: AppTextStyles.body(
                              size: 11, color: AppColors.textDark),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.body(size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PixelButton(
            label: '$price',
            onPressed: onBuy,
            width: 88,
            height: 44,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}

