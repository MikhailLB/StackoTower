import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/stacko_assets.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/site_background.dart';
import '../widgets/ui_kit.dart';

/// Spend earned coins on cosmetic block skins or consumable power-ups.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const Map<int, int> _skinPrices = {1: 10, 2: 100, 3: 500};
  static const int _firstComingSoonSkin = 4;

  static const _skipPrice = 90;
  static const _doubleCoinsPrice = 80;
  static const _luckyPrice = 30;

  bool _isComingSoon(int skin) => skin >= _firstComingSoonSkin;
  int? _priceOf(int skin) => _skinPrices[skin];

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

  Future<void> _buySkin(int skin) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (_isComingSoon(skin)) {
      _snack('Coming soon!');
      return;
    }
    if (progress.ownedSkins.contains(skin)) {
      await progress.setSelectedSkin(skin);
      return;
    }
    final price = _priceOf(skin);
    if (price == null) return;
    if (!await progress.spendCoins(price)) {
      _snack('Not enough coins');
      return;
    }
    await progress.unlockSkin(skin);
    await progress.setSelectedSkin(skin);
  }

  Future<void> _buyBoost(int price, Future<void> Function(int) grant) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (!await progress.spendCoins(price)) {
      _snack('Not enough coins');
      return;
    }
    await grant(1);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: NeonColors.cardFill,
        content: Text(text, style: AppTextStyles.body()),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final isRandom = progress.selectedSkin == 0;
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
                          Text('FORGE YARD',
                              style: AppTextStyles.body(
                                      size: 10, color: NeonColors.cyan)
                                  .copyWith(letterSpacing: 3)),
                          Text('Shop', style: AppTextStyles.title(size: 26)),
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
                    const SectionLabel('Block Skins'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 138,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, index) {
                          final skin = index + 1;
                          return _SkinCard(
                            skin: skin,
                            owned: progress.ownedSkins.contains(skin),
                            selected: progress.selectedSkin == skin,
                            price: _priceOf(skin),
                            comingSoon: _isComingSoon(skin),
                            onTap: () => _buySkin(skin),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeonCard(
                      edge: isRandom ? AppColors.accent : NeonColors.violet,
                      glow: isRandom,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: () {
                        AudioService.instance.playSfx(Sfx.buttonClick);
                        progress.setSelectedSkin(0);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.shuffle_rounded,
                              color: isRandom
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                              size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Random Rotation',
                                style: AppTextStyles.button(
                                    size: 16,
                                    color: isRandom
                                        ? AppColors.accent
                                        : AppColors.text)),
                          ),
                          if (isRandom)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accent, size: 22),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('Power-Ups'),
                    const SizedBox(height: 12),
                    _PowerCard(
                      icon: Icons.skip_next_rounded,
                      title: 'Skip Pass',
                      subtitle: 'Instantly clears a lot you are stuck on.',
                      price: _skipPrice,
                      owned: progress.skipBoosts,
                      accent: NeonColors.cyan,
                      onBuy: () => _buyBoost(_skipPrice, progress.grantSkip),
                    ),
                    const SizedBox(height: 10),
                    _PowerCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Double Coins',
                      subtitle: 'Doubles coin rewards for your next lot.',
                      price: _doubleCoinsPrice,
                      owned: progress.doubleCoinsBoosts,
                      accent: AppColors.accent,
                      onBuy: () =>
                          _buyBoost(_doubleCoinsPrice, progress.grantDoubleCoins),
                    ),
                    const SizedBox(height: 10),
                    _PowerCard(
                      icon: Icons.casino_rounded,
                      title: 'Lucky Bonus',
                      subtitle: '+20 bonus coins when you complete a lot.',
                      price: _luckyPrice,
                      owned: progress.luckyBoosts,
                      accent: NeonColors.violet,
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
    final edge = selected
        ? AppColors.accent
        : (owned ? NeonColors.cyan : NeonColors.violet);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 108,
        child: NeonCard(
          edge: edge,
          glow: selected,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: comingSoon ? 0.3 : 1,
                  child: Image.asset(StackoAssets.block(skin),
                      fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 4),
              if (comingSoon)
                Text('Soon',
                    style: AppTextStyles.body(size: 11, color: Colors.white60))
              else if (selected)
                Text('Active',
                    style: AppTextStyles.button(size: 12, color: AppColors.accent))
              else if (owned)
                Text('Owned',
                    style: AppTextStyles.body(size: 12, color: NeonColors.cyan))
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.accent, size: 13),
                    const SizedBox(width: 3),
                    Text('${price ?? 0}',
                        style: AppTextStyles.button(size: 13)),
                  ],
                ),
            ],
          ),
        ),
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
    return NeonCard(
      edge: accent,
      glow: false,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title,
                              style: AppTextStyles.button(size: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (owned > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.6)),
                            ),
                            child: Text('×$owned',
                                style: AppTextStyles.body(
                                    size: 11, color: accent)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppTextStyles.body(
                            size: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _BuyButton(price: price, onTap: onBuy),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.price, required this.onTap});
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD93D), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFC233).withValues(alpha: 0.35),
                blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text('$price',
                style: AppTextStyles.button(size: 15, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
