import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/stacko_assets.dart';
import '../game/route_controller.dart';
import '../game/route_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/pixel_button.dart';
import '../widgets/route_grid.dart';
import '../widgets/site_background.dart';

/// Hosts a single Site Paver puzzle. Pure Flutter — the [RouteController]
/// holds the logic and this screen renders it.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final RouteLevel level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RouteController _controller;
  final math.Random _rand = math.Random();
  late String _blockAsset;
  bool _rewarded = false;
  bool _usedDoubleCoins = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _blockAsset = StackoAssets.block(_pickSkin());
    _usedDoubleCoins = progress.doubleCoinsBoosts > 0;
    _showTutorial = !progress.tutorialSeen;
    _startRound();
    AudioService.instance.playBgm(Bgm.gameplay);
  }

  void _startRound() {
    _rewarded = false;
    _controller = RouteController(widget.level)..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  int _pickSkin() {
    final selected = progress.selectedSkin;
    final owned = progress.ownedSkins;
    if (owned.isEmpty) return 1;
    if (selected != 0 && owned.contains(selected)) return selected;
    return owned[_rand.nextInt(owned.length)];
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    unawaited(setOrientationsLockedPortrait());
    super.dispose();
  }

  void _onEnter(int r, int c) {
    final result = _controller.enter(r, c);
    switch (result) {
      case RouteMove.completed:
        unawaited(_onComplete());
        break;
      case RouteMove.retracted:
        AudioService.instance.playSfx(Sfx.buttonClick);
        break;
      case RouteMove.paved:
      case RouteMove.ignored:
        break;
    }
  }

  void _dismissTutorial() {
    setState(() => _showTutorial = false);
    progress.setTutorialSeen();
  }

  Future<void> _onComplete() async {
    if (_rewarded) return;
    _rewarded = true;
    AudioService.instance.playSfx(Sfx.levelComplete);

    await progress.completeLevel(widget.level.levelNumber);
    final solved = progress.completedLevels.length;
    if (solved > progress.highScore) {
      await progress.setHighScore(solved);
    }

    var coins = widget.level.coinReward;
    if (_usedDoubleCoins && progress.doubleCoinsBoosts > 0) {
      await progress.consumeDoubleCoins();
      coins *= 2;
    }
    if (progress.luckyBoosts > 0) {
      await progress.consumeLucky();
      coins += 20;
    }
    if (coins > 0) await progress.addCoins(coins);
  }

  void _onUndo() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.undo();
  }

  void _onReset() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.reset();
  }

  void _onPause() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.pause();
  }

  void _onResume() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.resume();
  }

  Future<void> _onSkip() async {
    final granted = await progress.consumeSkip();
    if (!granted) return;
    AudioService.instance.playSfx(Sfx.buttonClick);
    await progress.completeLevel(widget.level.levelNumber);
    if (mounted) Navigator.of(context).pop();
  }

  void _onExit() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (status == RouteStatus.routing) {
          _controller.pause();
        } else {
          _onExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.panelSolid,
        body: SiteBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      level: widget.level,
                      controller: _controller,
                      onPause: _onPause,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: RouteGrid(
                          controller: _controller,
                          blockAsset: _blockAsset,
                          onEnter: _onEnter,
                          onDragStart: () {},
                        ),
                      ),
                    ),
                    _ControlBar(onUndo: _onUndo, onReset: _onReset),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              if (status == RouteStatus.paused)
                _PauseOverlay(
                  onResume: _onResume,
                  onReset: () {
                    _onResume();
                    _onReset();
                  },
                  onExit: _onExit,
                  skipTokens: progress.skipBoosts,
                  onSkip: progress.skipBoosts > 0 ? _onSkip : null,
                ),
              if (status == RouteStatus.complete)
                _CompleteOverlay(
                  level: widget.level,
                  onNext: _onExit,
                  onReplay: () {
                    _onReset();
                  },
                  onExit: _onExit,
                ),
              if (_showTutorial)
                HowToPlayOverlay(onClose: _dismissTutorial),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.level,
    required this.controller,
    required this.onPause,
  });

  final RouteLevel level;
  final RouteController controller;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final paved = controller.pavedCount.clamp(0, controller.plotCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          _RoundButton(icon: Icons.pause_rounded, onTap: onPause),
          const Spacer(),
          Column(
            children: [
              Text(
                'LOT ${level.levelNumber}',
                style: AppTextStyles.body(size: 10, color: AppColors.accent)
                    .copyWith(letterSpacing: 2),
              ),
              Text(level.name, style: AppTextStyles.title(size: 22)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Text('PAVED',
                    style: AppTextStyles.body(size: 9, color: AppColors.textMuted)
                        .copyWith(letterSpacing: 1.5)),
                Text('$paved/${controller.plotCount}',
                    style: AppTextStyles.score(size: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: AppColors.text, size: 26),
        ),
      ),
    );
  }
}

// ─── Control bar ─────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.onUndo, required this.onReset});
  final VoidCallback onUndo;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ControlChip(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onTap: onUndo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ControlChip(
              icon: Icons.refresh_rounded,
              label: 'Reset',
              onTap: onReset,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.btnSecBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.text, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.button(size: 16)),
          ],
        ),
      ),
    );
  }
}

// ─── Overlays ────────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onReset,
    required this.onExit,
    required this.skipTokens,
    required this.onSkip,
  });
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onExit;
  final int skipTokens;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return _ModalScrim(
      child: _PanelCard(
        title: 'Paused',
        icon: Icons.pause_circle_rounded,
        children: [
          PixelButton(label: 'Continue', onPressed: onResume),
          const SizedBox(height: 12),
          PixelButton(
            label: 'Reset Lot',
            onPressed: onReset,
            color: PixelButtonColor.secondary,
          ),
          if (onSkip != null) ...[
            const SizedBox(height: 12),
            PixelButton(
              label: 'Skip Pass (x$skipTokens)',
              onPressed: onSkip,
              color: PixelButtonColor.secondary,
            ),
          ],
          const SizedBox(height: 12),
          PixelButton(
            label: 'Main Menu',
            onPressed: onExit,
            color: PixelButtonColor.secondary,
          ),
        ],
      ),
    );
  }
}

class _CompleteOverlay extends StatelessWidget {
  const _CompleteOverlay({
    required this.level,
    required this.onNext,
    required this.onReplay,
    required this.onExit,
  });

  final RouteLevel level;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isLast = level.levelNumber >= routeLevels.length;
    return _ModalScrim(
      child: _PanelCard(
        title: 'Lot Paved!',
        icon: Icons.verified_rounded,
        children: [
          Text(level.name, style: AppTextStyles.button(size: 18)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Text('+${level.coinReward} coins',
                    style: AppTextStyles.score(size: 20, color: AppColors.accent)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!isLast) ...[
            PixelButton(label: 'Continue', onPressed: onNext),
            const SizedBox(height: 12),
          ],
          PixelButton(
            label: 'Replay',
            onPressed: onReplay,
            color: PixelButtonColor.secondary,
          ),
        ],
      ),
    );
  }
}

class _ModalScrim extends StatelessWidget {
  const _ModalScrim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.68),
      alignment: Alignment.center,
      child: SingleChildScrollView(child: child),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 2),
        boxShadow: const [BoxShadow(blurRadius: 30, color: Colors.black54)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 36),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.title(size: 30)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
