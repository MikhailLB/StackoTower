import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/stacko_assets.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';
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
  late final AnimationController _floatCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    progress.addListener(_onProgressChanged);
    AudioService.instance.playBgm(Bgm.menu);
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    progress.removeListener(_onProgressChanged);
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLevelSelect() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LevelSelectScreen()),
    );
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  Future<void> _openShop() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
    );
  }

  Future<void> _openSettings() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _openPrivacy() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const InfoWebScreen(
          title: 'Privacy Policy',
          url: 'https://sttackotower.com/privacy-policy.html',
        ),
      ),
    );
  }

  Future<void> _openSupport() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const InfoWebScreen(
          title: 'Support',
          url: 'https://sttackotower.com/support.html',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- City background + gradient overlay ---
          Image.asset(StackoAssets.startBg, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xDD0D0D1F),
                  Color(0x881A1035),
                  Color(0xCC0D0D1F),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // --- Floating building ---
          Positioned(
            bottom: size.height * 0.14,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -6 + 12 * _floatCtrl.value),
                child: child,
              ),
              child: Image.asset(
                StackoAssets.startBuilding,
                width: size.width * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // --- Main UI ---
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Top bar
                    Row(
                      children: [
                        _StatPill(
                          icon: Icons.emoji_events_rounded,
                          value: 'Best ${progress.highScore}',
                          glow: AppColors.accent,
                        ),
                        const Spacer(),
                        _StatPill(
                          icon: Icons.monetization_on_rounded,
                          value: '${progress.coins}',
                          glow: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        _IconBtn(
                          icon: Icons.settings_rounded,
                          onTap: _openSettings,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Game logo / name
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        StackoAssets.gameName,
                        width: size.width * 0.82,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const Spacer(),

                    // Action buttons
                    Column(
                      children: [
                        PixelButton(
                          label: 'Play',
                          onPressed: _openLevelSelect,
                          width: size.width * 0.75,
                          height: 68,
                          fontSize: 26,
                          icon: Icons.play_arrow_rounded,
                        ),
                        const SizedBox(height: 14),
                        PixelButton(
                          label: 'Shop',
                          onPressed: _openShop,
                          width: size.width * 0.62,
                          height: 56,
                          fontSize: 22,
                          color: PixelButtonColor.secondary,
                          icon: Icons.storefront_rounded,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LinkButton(label: 'Privacy Policy', onTap: _openPrivacy),
                            _dot(),
                            _LinkButton(label: 'Support', onTap: _openSupport),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('·', style: TextStyle(color: Colors.white38, fontSize: 16)),
      );
}

// ─── Reusable sub-widgets ────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.glow,
  });
  final IconData icon;
  final String value;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.panelSolid.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: glow.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: glow, size: 20),
          const SizedBox(width: 7),
          Text(value, style: AppTextStyles.button(size: 17)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.panelSolid.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: AppColors.text, size: 22),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          label,
          style: AppTextStyles.body(size: 13, color: AppColors.textMuted).copyWith(
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
