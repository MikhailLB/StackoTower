import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/level_config.dart';
import '../game/stacko_game.dart';
import '../game/stacko_status.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';

/// Hosts the [StackoGame] inside a [GameWidget] and adds Flutter-side overlays
/// for the HUD, pause menu, game-over and level-complete screens.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelConfig});

  final LevelConfig levelConfig;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  StackoGame? _game;
  late final math.Random _rand = math.Random();
  bool _scoreSubmitted = false;
  int _coinsCreditedFor = 0;
  int _rotationIndex = 0;

  bool _usingDoubleCoins = false;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _spawnGame();
      });
    });
    AudioService.instance.playBgm(Bgm.gameplay);
  }

  @override
  void dispose() {
    unawaited(setOrientationsLockedPortrait());
    super.dispose();
  }

  void _spawnGame({
    bool slowHook = false,
    bool ghostBlock = false,
    bool speedFreeze = false,
    bool wideBase = false,
    bool doubleCoins = false,
  }) {
    _scoreSubmitted = false;
    _coinsCreditedFor = 0;
    _usingDoubleCoins = doubleCoins;
    final owned = progress.ownedSkins;
    _rotationIndex = owned.isEmpty ? 0 : _rand.nextInt(owned.length);
    _game = StackoGame(
      skinPicker: _pickSkin,
      levelConfig: widget.levelConfig,
      slowHookEnabled: slowHook,
      ghostBlockEnabled: ghostBlock,
      speedFreezeEnabled: speedFreeze,
      wideBaseEnabled: wideBase,
    );
  }

  int _pickSkin() {
    final selected = progress.selectedSkin;
    final owned = progress.ownedSkins;
    if (owned.isEmpty) return 1;
    if (selected != 0 && owned.contains(selected)) return selected;
    final skin = owned[_rotationIndex % owned.length];
    _rotationIndex++;
    return skin;
  }

  Future<void> _onPause() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _game?.setPaused(true);
  }

  void _onResume() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _game?.setPaused(false);
  }

  Future<void> _onUseSlowHook() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    final granted = await progress.consumeSlowHook();
    if (!granted) return;
    setState(() {
      _spawnGame(slowHook: true);
    });
  }

  Future<void> _onUseSecondChance() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    final granted = await progress.consumeSecondChance();
    if (!granted) return;
    _scoreSubmitted = false;
    _game?.requestSecondChance();
  }

  Future<void> _onRestart() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() {
      _spawnGame();
    });
  }

  Future<void> _onExit() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onNextLevel() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submitFinalScore(int score) async {
    if (_scoreSubmitted) return;
    _scoreSubmitted = true;
    if (score > progress.highScore) {
      await progress.setHighScore(score);
    }
    var delta = score - _coinsCreditedFor;
    if (_usingDoubleCoins && delta > 0) delta *= 2;
    if (delta > 0) {
      await progress.addCoins(delta);
      _coinsCreditedFor = score;
    }
  }

  Future<void> _onLevelComplete(int score) async {
    if (_scoreSubmitted) return;
    _scoreSubmitted = true;
    await progress.completeLevel(widget.levelConfig.levelNumber);
    if (score > progress.highScore) {
      await progress.setHighScore(score);
    }

    // Base coins per block scored.
    var coins = score;
    if (_usingDoubleCoins && coins > 0) coins *= 2;

    // Level completion reward.
    coins += widget.levelConfig.coinReward;

    // Lucky boost bonus.
    if (progress.luckyBoosts > 0) {
      await progress.consumeLucky();
      coins += 20;
    }

    if (coins > 0) await progress.addCoins(coins);
    AudioService.instance.playSfx(Sfx.levelComplete);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (game == null) {
          await _onExit();
          return;
        }
        final status = game.world.status.value;
        if (status == StackoStatus.swinging ||
            status == StackoStatus.falling) {
          game.setPaused(true);
        } else if (status == StackoStatus.paused ||
            status == StackoStatus.gameOver ||
            status == StackoStatus.levelComplete) {
          await _onExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.sky,
        body: game == null
            ? const _GameLoading()
            : _GameView(
                game: game,
                levelConfig: widget.levelConfig,
                onPause: _onPause,
                onResume: _onResume,
                onRestart: _onRestart,
                onExit: _onExit,
                onNextLevel: _onNextLevel,
                onUseSlowHook:
                    progress.slowHookBoosts > 0 ? _onUseSlowHook : null,
                onUseSecondChance: _onUseSecondChance,
                submitFinalScore: _submitFinalScore,
                onLevelComplete: _onLevelComplete,
              ),
      ),
    );
  }
}

class _GameLoading extends StatelessWidget {
  const _GameLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sky,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 4,
          ),
          const SizedBox(height: 18),
          Text('Stacking up...', style: AppTextStyles.button(size: 22)),
        ],
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView({
    required this.game,
    required this.levelConfig,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
    required this.onNextLevel,
    required this.onUseSlowHook,
    required this.onUseSecondChance,
    required this.submitFinalScore,
    required this.onLevelComplete,
  });

  final StackoGame game;
  final LevelConfig levelConfig;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback onNextLevel;
  final VoidCallback? onUseSlowHook;
  final Future<void> Function() onUseSecondChance;
  final Future<void> Function(int score) submitFinalScore;
  final Future<void> Function(int score) onLevelComplete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: GameWidget(
            key: ValueKey(game),
            game: game,
            backgroundBuilder: (_) => Container(color: AppColors.sky),
            loadingBuilder: (_) => const _GameLoading(),
            errorBuilder: (_, error) => Container(
              color: AppColors.sky,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load game:\n$error',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 18),
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: game.world.score,
          builder: (context, score, _) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _Hud(
                score: score,
                targetBlocks: levelConfig.targetBlocks,
                levelNumber: levelConfig.levelNumber,
                onPause: onPause,
                slowHooks: progress.slowHookBoosts,
                onUseSlowHook: onUseSlowHook,
              ),
            ),
          ),
        ),
        ValueListenableBuilder<StackoStatus>(
          valueListenable: game.world.status,
          builder: (context, status, _) {
            if (status == StackoStatus.paused) {
              return _PauseOverlay(onResume: onResume, onExit: onExit);
            }
            if (status == StackoStatus.gameOver) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await submitFinalScore(game.world.score.value);
              });
              return _GameOverOverlay(
                score: game.world.score.value,
                highScore: math.max(
                  progress.highScore,
                  game.world.score.value,
                ),
                secondChances: progress.secondChanceBoosts,
                onRestart: onRestart,
                onExit: onExit,
                onUseSecondChance:
                    progress.secondChanceBoosts > 0 &&
                            game.world.score.value > 0
                        ? () => onUseSecondChance()
                        : null,
              );
            }
            if (status == StackoStatus.levelComplete) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await onLevelComplete(game.world.score.value);
              });
              return _LevelCompleteOverlay(
                levelConfig: levelConfig,
                score: game.world.score.value,
                onNextLevel: onNextLevel,
                onRestart: onRestart,
                onExit: onExit,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.score,
    required this.targetBlocks,
    required this.levelNumber,
    required this.onPause,
    required this.slowHooks,
    required this.onUseSlowHook,
  });

  final int score;
  final int targetBlocks;
  final int levelNumber;
  final VoidCallback onPause;
  final int slowHooks;
  final VoidCallback? onUseSlowHook;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundButton(icon: Icons.pause_rounded, onPressed: onPause),
        const Spacer(),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black26),
              ),
              child: Text(
                'Level $levelNumber',
                style: AppTextStyles.body(size: 14, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black26),
              ),
              child: Text(
                '$score / $targetBlocks',
                style: AppTextStyles.score(size: 20),
              ),
            ),
          ],
        ),
        const Spacer(),
        if (slowHooks > 0)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RoundButton(
                icon: Icons.speed_rounded,
                onPressed: onUseSlowHook,
                tint: AppColors.accent.withValues(alpha: 0.85),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    'x$slowHooks',
                    style: AppTextStyles.body(size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          const SizedBox(width: 48, height: 48),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onPressed, this.tint});
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint ?? AppColors.panel,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.text, size: 28),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onExit});
  final VoidCallback onResume;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _ModalScrim(
      child: _PanelCard(
        title: 'Paused',
        children: [
          PixelButton(label: 'Continue', onPressed: onResume),
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

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.highScore,
    required this.secondChances,
    required this.onRestart,
    required this.onExit,
    required this.onUseSecondChance,
  });

  final int score;
  final int highScore;
  final int secondChances;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback? onUseSecondChance;

  @override
  Widget build(BuildContext context) {
    return _ModalScrim(
      child: _PanelCard(
        title: 'Game Over',
        children: [
          Text('Blocks: $score', style: AppTextStyles.score(size: 26)),
          Text(
            'Best: $highScore',
            style: AppTextStyles.body(size: 16, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          if (onUseSecondChance != null) ...[
            PixelButton(
              label: 'Second Chance (x$secondChances)',
              onPressed: onUseSecondChance,
              fontSize: 18,
            ),
            const SizedBox(height: 12),
          ],
          PixelButton(label: 'Retry', onPressed: onRestart),
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

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({
    required this.levelConfig,
    required this.score,
    required this.onNextLevel,
    required this.onRestart,
    required this.onExit,
  });

  final LevelConfig levelConfig;
  final int score;
  final VoidCallback onNextLevel;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isLastLevel = levelConfig.levelNumber >= levels.length;
    return _ModalScrim(
      child: _PanelCard(
        title: 'Level Complete!',
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.accent, size: 24),
                const SizedBox(width: 8),
                Text(
                  '+${levelConfig.coinReward} coins',
                  style: AppTextStyles.score(
                      size: 22, color: AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score blocks stacked',
            style: AppTextStyles.body(size: 14, color: Colors.white70),
          ),
          const SizedBox(height: 18),
          if (!isLastLevel) ...[
            PixelButton(label: 'Next Level', onPressed: onNextLevel),
            const SizedBox(height: 12),
          ],
          PixelButton(label: 'Play Again', onPressed: onRestart),
          const SizedBox(height: 12),
          PixelButton(
            label: 'Level Select',
            onPressed: onExit,
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
      color: Colors.black54,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [
          BoxShadow(blurRadius: 30, color: Colors.black54),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.title(size: 34)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

