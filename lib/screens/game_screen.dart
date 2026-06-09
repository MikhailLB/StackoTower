import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/stacko_assets.dart';
import '../game/achievements.dart';
import '../game/level_forge.dart';
import '../game/road_themes.dart';
import '../game/route_controller.dart';
import '../game/route_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/how_to_play.dart';
import '../widgets/pixel_button.dart';
import '../widgets/route_grid.dart';
import '../widgets/site_background.dart';

enum GameMode { campaign, endless, daily }

/// Hosts a single Site Paver puzzle. Pure Flutter — the [RouteController]
/// holds the logic and this screen renders it.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    this.mode = GameMode.campaign,
    this.endlessStage = 0,
  });

  final RouteLevel level;
  final GameMode mode;
  final int endlessStage;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RouteController _controller;
  late RouteLevel _level;
  late int _endlessStage;
  int _endlessStreak = 0;

  final math.Random _rand = math.Random();
  late String _blockAsset;
  final Stopwatch _watch = Stopwatch();

  bool _rewarded = false;
  bool _usedDoubleCoins = false;
  bool _showTutorial = false;
  int _undoCount = 0;
  int _resetCount = 0;

  // Complete-overlay payload.
  int _awardedCoins = 0;
  int _earnedStars = 0;
  int _starBonus = 0;
  int _dailyStreakResult = 0;
  List<Achievement> _newAwards = const [];

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _level = widget.level;
    _endlessStage = widget.endlessStage;
    _blockAsset = StackoAssets.block(_pickSkin());
    _usedDoubleCoins = progress.doubleCoinsBoosts > 0;
    _showTutorial = !progress.tutorialSeen;
    _startRound();
    AudioService.instance.playBgm(Bgm.gameplay);
  }

  void _startRound() {
    _rewarded = false;
    _undoCount = 0;
    _resetCount = 0;
    _awardedCoins = 0;
    _earnedStars = 0;
    _starBonus = 0;
    _newAwards = const [];
    _watch
      ..reset()
      ..start();
    _controller = RouteController(_level)..addListener(_onTick);
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

  int get _potentialStars {
    final mistakes = _undoCount + _resetCount;
    if (mistakes == 0) return 3;
    if (mistakes <= 3) return 2;
    return 1;
  }

  void _onEnter(int r, int c) {
    final result = _controller.enter(r, c);
    switch (result) {
      case RouteMove.completed:
        unawaited(_onComplete());
        break;
      case RouteMove.paved:
        AudioService.instance.playSfx(Sfx.blockLand);
        break;
      case RouteMove.retracted:
        AudioService.instance.playSfx(Sfx.buttonClick);
        break;
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
    _watch.stop();
    AudioService.instance.playSfx(Sfx.levelComplete);
    AudioService.instance.vibrate(heavy: true);

    final stars = _potentialStars;
    var coins = _level.coinReward;

    switch (widget.mode) {
      case GameMode.campaign:
        await progress.completeLevel(_level.levelNumber);
        final solved = progress.completedLevels.length;
        if (solved > progress.highScore) {
          await progress.setHighScore(solved);
        }
        final newStars =
            await progress.recordLevelStars(_level.levelNumber, stars);
        _starBonus = newStars * 25;
        coins += _starBonus;
        _earnedStars = stars;
        break;
      case GameMode.endless:
        _endlessStreak++;
        await progress.recordEndlessSolve(_endlessStreak);
        break;
      case GameMode.daily:
        _dailyStreakResult = await progress.recordDailySolve(DateTime.now());
        coins += math.min(_dailyStreakResult - 1, 10) * 15;
        break;
    }

    if (_usedDoubleCoins && progress.doubleCoinsBoosts > 0) {
      await progress.consumeDoubleCoins();
      await progress.recordBoostUsed();
      coins *= 2;
    }
    if (progress.luckyBoosts > 0) {
      await progress.consumeLucky();
      await progress.recordBoostUsed();
      coins += 20;
    }
    if (coins > 0) await progress.addCoins(coins);
    _awardedCoins = coins;

    await progress.recordRoundStats(
      plotsPaved: _level.plotCount,
      undos: _undoCount,
      perfect: widget.mode == GameMode.campaign && stars == 3,
      playSeconds: _watch.elapsed.inSeconds,
    );

    _newAwards = await syncAchievements(progress);
    if (mounted) setState(() {});
  }

  void _onUndo() {
    if (!_controller.isRouting || _controller.pavedCount <= 1) return;
    AudioService.instance.playSfx(Sfx.buttonClick);
    _undoCount++;
    _controller.undo();
  }

  void _onReset() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (_controller.pavedCount > 1) _resetCount++;
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
    await progress.recordBoostUsed();
    if (widget.mode == GameMode.campaign) {
      await progress.completeLevel(_level.levelNumber);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _onExit() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop();
  }

  void _onNextLevel() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    final next = _level.levelNumber + 1;
    if (next > routeLevels.length) {
      _onExit();
      return;
    }
    setState(() {
      _controller.removeListener(_onTick);
      _controller.dispose();
      _level = routeLevelByNumber(next);
      _startRound();
    });
  }

  void _onNextShift() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() {
      _controller.removeListener(_onTick);
      _controller.dispose();
      _endlessStage++;
      _level = LevelForge.endless(_endlessStage);
      _startRound();
    });
  }

  void _onReplay() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() {
      _controller.removeListener(_onTick);
      _controller.dispose();
      _startRound();
    });
  }

  String get _modeLabel {
    switch (widget.mode) {
      case GameMode.campaign:
        return 'LOT ${_level.levelNumber}';
      case GameMode.endless:
        return 'ENDLESS SHIFT';
      case GameMode.daily:
        return 'DAILY BLUEPRINT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;
    final theme = roadThemeById(progress.selectedTheme);
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
                      label: _modeLabel,
                      level: _level,
                      controller: _controller,
                      potentialStars:
                          widget.mode == GameMode.campaign ? _potentialStars : null,
                      onPause: _onPause,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: RouteGrid(
                          controller: _controller,
                          blockAsset: _blockAsset,
                          roadColor: theme.color,
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
                  mode: widget.mode,
                  level: _level,
                  coins: _awardedCoins,
                  stars: _earnedStars,
                  starBonus: _starBonus,
                  dailyStreak: _dailyStreakResult,
                  endlessStreak: _endlessStreak,
                  newAwards: _newAwards,
                  onNext: widget.mode == GameMode.endless
                      ? _onNextShift
                      : (widget.mode == GameMode.campaign &&
                              _level.levelNumber < routeLevels.length
                          ? _onNextLevel
                          : null),
                  onReplay: _onReplay,
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
    required this.label,
    required this.level,
    required this.controller,
    required this.potentialStars,
    required this.onPause,
  });

  final String label;
  final RouteLevel level;
  final RouteController controller;
  final int? potentialStars;
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
                label,
                style: AppTextStyles.body(size: 10, color: AppColors.accent)
                    .copyWith(letterSpacing: 2),
              ),
              Text(level.name, style: AppTextStyles.title(size: 22)),
              if (potentialStars != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: i < potentialStars!
                              ? AppColors.accent
                              : Colors.white24,
                        ),
                    ],
                  ),
                ),
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
    required this.mode,
    required this.level,
    required this.coins,
    required this.stars,
    required this.starBonus,
    required this.dailyStreak,
    required this.endlessStreak,
    required this.newAwards,
    required this.onNext,
    required this.onReplay,
    required this.onExit,
  });

  final GameMode mode;
  final RouteLevel level;
  final int coins;
  final int stars;
  final int starBonus;
  final int dailyStreak;
  final int endlessStreak;
  final List<Achievement> newAwards;
  final VoidCallback? onNext;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  String get _title {
    switch (mode) {
      case GameMode.campaign:
        return 'Lot Paved!';
      case GameMode.endless:
        return 'Shift Cleared!';
      case GameMode.daily:
        return 'Blueprint Done!';
    }
  }

  String get _nextLabel {
    switch (mode) {
      case GameMode.campaign:
        return 'Next Lot';
      case GameMode.endless:
        return 'Next Shift';
      case GameMode.daily:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ModalScrim(
      child: _PanelCard(
        title: _title,
        icon: Icons.verified_rounded,
        children: [
          Text(level.name, style: AppTextStyles.button(size: 18)),
          if (mode == GameMode.campaign) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.star_rounded,
                      size: 38,
                      color: i < stars ? AppColors.accent : Colors.white24,
                      shadows: i < stars
                          ? const [
                              Shadow(blurRadius: 12, color: Color(0xAAFF8800)),
                            ]
                          : null,
                    ),
                  ),
              ],
            ),
          ],
          if (mode == GameMode.daily && dailyStreak > 0) ...[
            const SizedBox(height: 8),
            _InfoChip(
              icon: Icons.local_fire_department_rounded,
              label: '$dailyStreak-day streak',
            ),
          ],
          if (mode == GameMode.endless && endlessStreak > 0) ...[
            const SizedBox(height: 8),
            _InfoChip(
              icon: Icons.bolt_rounded,
              label: 'Streak: $endlessStreak',
            ),
          ],
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
                Text('+$coins coins',
                    style: AppTextStyles.score(size: 20, color: AppColors.accent)),
              ],
            ),
          ),
          if (starBonus > 0) ...[
            const SizedBox(height: 6),
            Text('incl. +$starBonus star bonus',
                style: AppTextStyles.body(size: 12, color: AppColors.textMuted)),
          ],
          for (final award in newAwards) ...[
            const SizedBox(height: 8),
            _AwardChip(award: award),
          ],
          const SizedBox(height: 18),
          if (onNext != null) ...[
            PixelButton(label: _nextLabel, onPressed: onNext),
            const SizedBox(height: 12),
          ],
          PixelButton(
            label: 'Replay',
            onPressed: onReplay,
            color: PixelButtonColor.secondary,
          ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.button(size: 13)),
        ],
      ),
    );
  }
}

class _AwardChip extends StatelessWidget {
  const _AwardChip({required this.award});
  final Achievement award;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF35E0E0).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF35E0E0).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(award.icon, color: const Color(0xFF35E0E0), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Award: ${award.title}  +${award.coinReward}',
              style: AppTextStyles.button(size: 13, color: const Color(0xFF35E0E0)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
