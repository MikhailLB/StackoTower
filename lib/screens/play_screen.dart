import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/skyline.dart';
import '../game/achievements.dart';
import '../game/campaign.dart';
import '../game/tower_engine.dart';
import '../main.dart';
import '../widgets/tower_view.dart';
import 'bonus_game_screen.dart';
import 'rush_game_screen.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.mode,
    this.level,
    this.seed,
  });

  final GameMode mode;
  final CampaignLevel? level;
  final int? seed;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with TickerProviderStateMixin {
  late final TowerEngine _engine;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final DateTime _startedAt = DateTime.now();

  late final AnimationController _topple;
  bool _resolved = false;
  bool _resultShown = false;
  late bool _introVisible;
  late bool _coachVisible;

  TowerSkin get _skin => widget.mode == GameMode.campaign && widget.level != null
      ? TowerSkin.byIndex(widget.level!.district.skin)
      : TowerSkin.byIndex(progress.selectedTheme);

  @override
  void initState() {
    super.initState();
    _engine = _buildEngine();
    _introVisible = widget.mode == GameMode.campaign &&
        widget.level != null &&
        (widget.level!.isChapterStart || widget.level!.isBoss);
    final lv = widget.level;
    _coachVisible = widget.mode == GameMode.campaign &&
        lv != null &&
        lv.tip != null &&
        !progress.hasTip(lv.tipId ?? '');
    _topple = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _ticker = createTicker(_tick)..start();
    _engine.addListener(_onEngine);
  }

  TowerEngine _buildEngine() {
    final eb = progress.extraBaseHalf;
    final sm = progress.speedMul;
    switch (widget.mode) {
      case GameMode.campaign:
        return (widget.level ?? campaignLevel(1))
            .build(extraBaseHalf: eb, speedMul: sm);
      case GameMode.daily:
        return TowerEngine(
          mode: GameMode.daily,
          goal: 18,
          seed: widget.seed,
          startSpeed: 1.5,
          windMax: 0.09,
          extraBaseHalf: eb,
          speedMul: sm,
        );
      case GameMode.endless:
        return TowerEngine(
          mode: GameMode.endless,
          startSpeed: 1.35,
          windMax: 0.08,
          extraBaseHalf: eb,
          speedMul: sm,
        );
    }
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.1) return; // skip first/huge frames
    _engine.update(dt);
  }

  void _onEngine() {
    if (!_resolved && (_engine.isOver || _engine.isWon)) {
      _resolved = true;
      HapticFeedback.heavyImpact();
      if (_engine.isOver) {
        _topple.forward().whenComplete(_finish);
      } else {
        _finish();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _finish() async {
    if (_resultShown) return;
    _resultShown = true;
    _ticker.stop();

    final height = _engine.height;
    final playSeconds = DateTime.now().difference(_startedAt).inSeconds;
    var coins = height * 5 + _engine.bonusCoins;
    var stars = 0;

    if (widget.mode == GameMode.campaign && _engine.isWon) {
      final ratio = height > 0 ? _engine.perfectDrops / height : 0;
      stars = ratio >= 0.6 ? 3 : (ratio >= 0.3 ? 2 : 1);
      coins += widget.level!.coinReward;
      if (widget.level!.isBoss) {
        await progress.markBossBeaten(widget.level!.district.index);
      }
      await progress.recordLevelStars(widget.level!.number, stars);
      await progress.completeLevel(widget.level!.number);
    } else if (widget.mode == GameMode.daily && _engine.isWon) {
      coins += 120;
      await progress.recordDailySolve(DateTime.now());
    } else {
      // Endless (or failed run): score by height.
      await progress.setHighScore(height);
      await progress.recordEndlessSolve(_engine.bestCombo);
    }

    if (await progress.consumeDoubleCoins()) {
      coins *= 2;
      await progress.recordBoostUsed();
    }
    if (await progress.consumeLucky()) {
      coins += 50;
      await progress.recordBoostUsed();
    }
    coins = (coins * progress.payoutMul).round();

    await progress.addCoins(coins);
    await progress.recordRoundStats(
      plotsPaved: height,
      undos: 0,
      perfect: _engine.perfectDrops > 0,
      playSeconds: playSeconds,
    );
    final unlocked = await syncAchievements(progress);

    if (!mounted) return;
    setState(() {});
    _showResult(coins: coins, stars: stars, unlocked: unlocked);
  }

  void _drop() {
    if (_introVisible || _coachVisible || !_engine.running) return;
    HapticFeedback.selectionClick();
    _engine.drop();
    if (_engine.lastResult == DropResult.perfect) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _useStabiliser() async {
    if (!_engine.running) return;
    if (await progress.consumeSkip()) {
      await progress.recordBoostUsed();
      _engine.stabilise();
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _useSlow() async {
    if (!_engine.running) return;
    if (await progress.consumeSlow()) {
      await progress.recordBoostUsed();
      _engine.slowMo();
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _useWiden() async {
    if (!_engine.running) return;
    if (await progress.consumeWiden()) {
      await progress.recordBoostUsed();
      _engine.widen();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngine);
    _ticker.dispose();
    _topple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = _engine.leanPct.abs() > 0.7 ? Sky.danger : Sky.violet;
    return Scaffold(
      body: SkyBackdrop(
        glowColor: glow,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _drop(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _topple,
                    builder: (_, _) =>
                        TowerView(engine: _engine, skin: _skin, toppleT: _topple.value),
                  ),
                ),
                _hud(),
                if (_introVisible) _introCard(),
                if (!_introVisible && _coachVisible) _coachCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
    final lv = widget.level!;
    final d = lv.district;
    final boss = lv.boss;
    final accent = boss != null ? Sky.danger : Sky.cyan;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.82),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (boss != null) ...[
              Icon(Icons.warning_amber_rounded, color: Sky.danger, size: 44),
              const SizedBox(height: 8),
              Text('BOSS FLOOR', style: Sky.body(size: 13, color: Sky.danger)),
              const SizedBox(height: 6),
              Text(boss.name.toUpperCase(),
                  style: Sky.display(size: 30, color: Sky.danger),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Text(boss.tagline,
                  style: Sky.body(size: 15), textAlign: TextAlign.center),
              const SizedBox(height: 18),
            ] else ...[
              Text('CHAPTER ${d.index + 1}',
                  style: Sky.body(size: 13, color: Sky.cyan)),
              const SizedBox(height: 6),
              Text(d.name.toUpperCase(),
                  style: Sky.display(size: 28), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(d.lore,
                  style: Sky.body(size: 15), textAlign: TextAlign.center),
              const SizedBox(height: 18),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Sky.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Sky.lime.withValues(alpha: 0.5)),
              ),
              child: Text('◎  ${widget.level!.goalText()}',
                  style: Sky.label(size: 15, color: Sky.lime)),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => setState(() => _introVisible = false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: Sky.glow(accent, blur: 16),
                ),
                child: Text(boss != null ? 'FIGHT' : 'BUILD',
                    style: Sky.label(size: 18, color: Sky.bg0, spacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coachCard() {
    final lv = widget.level!;
    return Positioned(
      left: 20,
      right: 20,
      bottom: 40,
      child: GestureDetector(
        onTap: () async {
          await progress.markTipSeen(lv.tipId ?? '');
          if (mounted) setState(() => _coachVisible = false);
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Sky.panel, Sky.panelDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Sky.cyan.withValues(alpha: 0.6), width: 1.5),
            boxShadow: Sky.glow(Sky.cyan, blur: 18),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Sky.cyan, size: 28),
              const SizedBox(width: 14),
              Expanded(child: Text(lv.tip!, style: Sky.body(size: 14, color: Sky.text))),
              const SizedBox(width: 10),
              Text('GOT IT', style: Sky.label(size: 13, color: Sky.cyan)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hud() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _backButton(),
              const Spacer(),
              if (_engine.hasDeadline) ...[
                _chip(Icons.timer_rounded, '${_engine.remaining.ceil()}s',
                    _engine.remaining < 5 ? Sky.danger : Sky.amber),
                const SizedBox(width: 8),
              ],
              _chip(Icons.height_rounded, '${_engine.height}', Sky.cyan),
              const SizedBox(width: 8),
              if (widget.mode == GameMode.endless)
                _chip(Icons.emoji_events_rounded, '${progress.highScore}', Sky.amber)
              else
                _chip(Icons.flag_rounded, _engine.goalLabel, Sky.lime),
            ],
          ),
          if (widget.mode != GameMode.endless) ...[
            const SizedBox(height: 10),
            _goalBar(),
          ],
          const SizedBox(height: 14),
          LeanMeter(leanPct: _engine.leanPct),
          if (_engine.combo > 1) ...[
            const SizedBox(height: 8),
            Text('COMBO ×${_engine.combo}',
                style: Sky.label(size: 18, color: Sky.magenta)),
          ],
          const Spacer(),
          if (_engine.running) _bottomBar(),
        ],
      ),
    );
  }

  Widget _goalBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _engine.goalProgress,
        minHeight: 6,
        backgroundColor: Sky.panelDeep,
        valueColor: const AlwaysStoppedAnimation(Sky.lime),
      ),
    );
  }

  Widget _bottomBar() {
    return Row(
      children: [
        _nextPreview('NEXT', _engine.nextKind, _skin),
        const SizedBox(width: 10),
        _nextPreview('AFTER', _engine.afterKind, _skin),
        const Spacer(),
        _boostButton(Icons.balance_rounded, progress.skipBoosts, Sky.lime, _useStabiliser),
        const SizedBox(width: 8),
        _boostButton(Icons.slow_motion_video_rounded, progress.slowBoosts, Sky.cyan, _useSlow),
        const SizedBox(width: 8),
        _boostButton(Icons.open_in_full_rounded, progress.widenBoosts, Sky.violet, _useWiden),
      ],
    );
  }

  Widget _boostButton(IconData icon, int count, Color color, VoidCallback onTap) {
    final on = count > 0;
    return GestureDetector(
      onTap: on ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: Sky.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: (on ? color : Sky.muted).withValues(alpha: 0.6), width: 1.4),
          boxShadow: on ? Sky.glow(color, blur: 10) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: on ? color : Sky.muted, size: 20),
            const SizedBox(width: 5),
            Text('$count', style: Sky.number(size: 15)),
          ],
        ),
      ),
    );
  }

  Widget _nextPreview(String label, BlockKind kind, TowerSkin skin) {
    final c = skin.colorFor(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Sky.body(size: 11)),
        const SizedBox(height: 4),
        Container(
          width: 46,
          height: 22,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(6),
            boxShadow: Sky.glow(c, blur: 8),
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Sky.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(text, style: Sky.number(size: 16)),
      ]),
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Sky.panel,
          shape: BoxShape.circle,
          border: Border.all(color: Sky.violet.withValues(alpha: 0.5), width: 1.4),
        ),
        child: const Icon(Icons.close_rounded, color: Sky.text, size: 22),
      ),
    );
  }

  void _showResult({
    required int coins,
    required int stars,
    required List<Achievement> unlocked,
  }) {
    final won = _engine.isWon;
    final isCampaign = widget.mode == GameMode.campaign && widget.level != null;
    final chapterEnd = won && isCampaign && widget.level!.isChapterEnd;
    final hasNext =
        won && isCampaign && widget.level!.number < campaignCount;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _ResultDialog(
        won: won,
        bossWin: won && isCampaign && widget.level!.isBoss,
        height: _engine.height,
        coins: coins,
        stars: stars,
        bestCombo: _engine.bestCombo,
        unlocked: unlocked,
        onNext: hasNext
            ? () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => PlayScreen(
                    mode: GameMode.campaign,
                    level: campaignLevel(widget.level!.number + 1),
                  ),
                ));
              }
            : null,
        onBonus: chapterEnd
            ? () {
                Navigator.of(ctx).pop();
                final rush = math.Random().nextBool();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) =>
                      rush ? const RushGameScreen() : const BonusGameScreen(),
                ));
              }
            : null,
        onReplay: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PlayScreen(
                mode: widget.mode, level: widget.level, seed: widget.seed),
          ));
        },
        onHome: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).maybePop();
        },
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.won,
    this.bossWin = false,
    required this.height,
    required this.coins,
    required this.stars,
    required this.bestCombo,
    required this.unlocked,
    required this.onReplay,
    required this.onHome,
    this.onBonus,
    this.onNext,
  });

  final bool won;
  final bool bossWin;
  final int height;
  final int coins;
  final int stars;
  final int bestCombo;
  final List<Achievement> unlocked;
  final VoidCallback onReplay;
  final VoidCallback onHome;
  final VoidCallback? onBonus;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Sky.panel, Sky.panelDeep],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: (won ? Sky.lime : Sky.danger).withValues(alpha: 0.6),
              width: 1.6),
          boxShadow: Sky.glow(won ? Sky.lime : Sky.danger, blur: 28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bossWin ? 'BOSS DEFEATED' : (won ? 'FLOOR SECURED' : 'TOWER DOWN'),
                style: Sky.display(
                    size: bossWin ? 22 : 24,
                    color: bossWin ? Sky.amber : (won ? Sky.lime : Sky.danger))),
            const SizedBox(height: 16),
            if (stars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i < stars ? Sky.amber : Sky.muted,
                      size: 40,
                    ),
                ],
              ),
            const SizedBox(height: 16),
            _statRow(Icons.height_rounded, 'Height', '$height', Sky.cyan),
            _statRow(Icons.local_fire_department_rounded, 'Best combo', '$bestCombo', Sky.magenta),
            _statRow(Icons.monetization_on_rounded, 'Coins', '+$coins', Sky.amber),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final a in unlocked)
                Text('🏆 ${a.title}',
                    style: Sky.body(size: 14, color: Sky.lime)),
            ],
            const SizedBox(height: 22),
            if (onBonus != null) ...[
              _btn('🎁  BONUS ROUND', Sky.amber, onBonus!, filled: true),
              const SizedBox(height: 12),
            ],
            if (onNext != null) ...[
              _btn('NEXT LEVEL', Sky.lime, onNext!, filled: true),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _btn('HOME', Sky.violet, onHome, filled: false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _btn('RETRY', Sky.cyan, onReplay, filled: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: Sky.body(size: 15)),
          const Spacer(),
          Text(value, style: Sky.number(size: 18, color: color)),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap, {required bool filled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.6),
          boxShadow: filled ? Sky.glow(color, blur: 14) : null,
        ),
        child: Text(label,
            style: Sky.label(
                size: 16, color: filled ? Sky.bg0 : color, spacing: 1.5)),
      ),
    );
  }
}
