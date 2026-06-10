import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Module types delivered by the crane. Width is a HALF-width in board space
/// (board spans x ∈ [-1, 1]); mass drives the centre-of-mass balance layer.
enum BlockKind { normal, wide, light, counter, bonus, fragile, ice, bomb }

extension BlockKindInfo on BlockKind {
  double get halfW {
    switch (this) {
      case BlockKind.normal:
        return 0.16;
      case BlockKind.wide:
        return 0.24;
      case BlockKind.light:
        return 0.15;
      case BlockKind.counter:
        return 0.13;
      case BlockKind.bonus:
        return 0.15;
      case BlockKind.fragile:
        return 0.14;
      case BlockKind.ice:
        return 0.16;
      case BlockKind.bomb:
        return 0.15;
    }
  }

  double get mass {
    switch (this) {
      case BlockKind.normal:
        return 1.0;
      case BlockKind.wide:
        return 1.3;
      case BlockKind.light:
        return 0.5;
      case BlockKind.counter:
        return 2.6;
      case BlockKind.bonus:
        return 1.0;
      case BlockKind.fragile:
        return 0.8;
      case BlockKind.ice:
        return 0.9;
      case BlockKind.bomb:
        return 1.0;
    }
  }
}

/// A placed (possibly trimmed) module: [x] is its centre, [halfW] its
/// half-width after any overhang was sliced off.
class TowerBlock {
  TowerBlock({required this.x, required this.halfW, required this.kind, this.perfect = false});
  final double x;
  final double halfW;
  final BlockKind kind;
  final bool perfect;
  double get mass => kind.mass;
  double get left => x - halfW;
  double get right => x + halfW;
}

enum GameMode { endless, campaign, daily }

/// What finishing a contract requires.
enum GoalType { height, survive, perfects, limited }

/// Per-floor rule/setting twists — give every level its own logic & feel.
enum FloorMod {
  wind,
  quake,
  narrow,
  heavy,
  fast,
  fog,
  fragileRain,
  gusts,
  deadline, // a countdown — reach the goal before it hits zero
  pulseSwing, // the crane's rhythm speeds up and slows down
  drift, // the whole tower sways slowly side to side
  reverse, // the crane starts swinging the other way
  iceRain, // mostly slippery ice modules
  shrink, // the base slowly narrows as you climb
  escalate, // wind & swing speed ramp up over time (boss phases)
}

enum EngineState { swinging, over, won }

/// Outcome of the last drop, so the UI can juice feedback.
enum DropResult { none, placed, perfect, trimmed, miss }

/// Pure-logic controller for STACKO TOWER: Balance.
///
/// A crane swings a module; releasing stacks it. A block must OVERLAP the one
/// below — any overhang is sliced off and the tower narrows, so careless taps
/// quickly miss and topple. On top of that, every block shifts the centre of
/// mass while drifting wind and quakes try to tip the whole tower over.
class TowerEngine extends ChangeNotifier {
  TowerEngine({
    required this.mode,
    this.goalType = GoalType.height,
    this.goal,
    int? seed,
    this.startSpeed = 1.4,
    this.windMax = 0.08,
    this.mods = const <FloorMod>{},
    this.extraBaseHalf = 0,
    this.speedMul = 1,
  }) : _rng = math.Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    _baseHalf = (mods.contains(FloorMod.narrow) ? 0.15 : 0.22) + extraBaseHalf;
    _supportL = -_baseHalf;
    _supportR = _baseHalf;
    _speed = startSpeed * (mods.contains(FloorMod.fast) ? 1.4 : 1.0) * speedMul;
    if (mods.contains(FloorMod.reverse)) _phase = math.pi;
    if (mods.contains(FloorMod.deadline)) {
      _remaining = 16 + (goal ?? 10) * 1.4;
    }
    _nextKind = _rollKind();
    _afterKind = _rollKind();
  }

  final GameMode mode;
  final GoalType goalType;
  final int? goal;
  final double startSpeed;
  final double windMax;
  final Set<FloorMod> mods;
  final double extraBaseHalf;
  final double speedMul;
  final math.Random _rng;

  // ── Crane ────────────────────────────────────────────────
  static const double amplitude = 0.82;
  double _phase = 0;
  double _speed = 1.4;
  double _pulsePhase = 0;
  double _slowTimer = 0;
  double get craneX => math.sin(_phase) * amplitude;
  double get craneSpeed {
    var s = _speed + blocks.length * 0.045;
    if (mods.contains(FloorMod.pulseSwing)) {
      s *= 1 + 0.6 * math.sin(_pulsePhase);
    }
    if (_slowTimer > 0) s *= 0.45;
    return s;
  }

  bool get slowActive => _slowTimer > 0;

  // ── Tower ────────────────────────────────────────────────
  final List<TowerBlock> blocks = [];
  late double _baseHalf;
  late double _supportL;
  late double _supportR;

  double _windBias = 0;
  double _windTarget = 0;
  double _windTimer = 0;
  double _quakePhase = 0;
  double _driftPhase = 0;
  double _elapsed = 0;
  double _remaining = 0;

  bool get hasDeadline => mods.contains(FloorMod.deadline);
  double get remaining => _remaining;

  int combo = 0;
  int bestCombo = 0;
  int perfectDrops = 0;
  int bonusCoins = 0;
  DropResult lastResult = DropResult.none;
  EngineState state = EngineState.swinging;

  late BlockKind _nextKind;
  late BlockKind _afterKind;
  BlockKind get nextKind => _nextKind;
  BlockKind get afterKind => _afterKind;

  static const double leanLimit = 0.5;
  static const double _minOverlap = 0.012;

  double get supportCentre => (_supportL + _supportR) / 2;
  double get supportLeft => _supportL;
  double get supportRight => _supportR;
  double get baseHalf => _baseHalf;

  double get centreOfMass {
    if (blocks.isEmpty) return 0;
    var m = 0.0, mx = 0.0;
    for (final b in blocks) {
      m += b.mass;
      mx += b.mass * b.x;
    }
    return mx / m;
  }

  double get _quakeOffset =>
      mods.contains(FloorMod.quake) ? math.sin(_quakePhase) * 0.16 : 0;
  double get _driftOffset =>
      mods.contains(FloorMod.drift) ? math.sin(_driftPhase) * 0.20 : 0;

  double get effectiveLean =>
      centreOfMass + _windBias + _quakeOffset + _driftOffset;
  double get leanPct => (effectiveLean / leanLimit).clamp(-1.5, 1.5);
  double get windBias => _windBias;
  int get height => blocks.length;
  double get elapsed => _elapsed;
  bool get isOver => state == EngineState.over;
  bool get isWon => state == EngineState.won;
  bool get running => state == EngineState.swinging;

  /// 0..1 progress toward the current goal (for the HUD bar).
  double get goalProgress {
    final g = goal;
    if (g == null || g == 0) return 0;
    switch (goalType) {
      case GoalType.height:
      case GoalType.limited:
        return (blocks.length / g).clamp(0, 1);
      case GoalType.perfects:
        return (perfectDrops / g).clamp(0, 1);
      case GoalType.survive:
        return (_elapsed / g).clamp(0, 1);
    }
  }

  String get goalLabel {
    final g = goal ?? 0;
    switch (goalType) {
      case GoalType.height:
        return '${blocks.length}/$g';
      case GoalType.limited:
        return '${blocks.length}/$g';
      case GoalType.perfects:
        return '$perfectDrops/$g ◎';
      case GoalType.survive:
        return '${_elapsed.ceil()}/${g}s';
    }
  }

  BlockKind _rollKind() {
    final r = _rng.nextDouble();
    if (mods.contains(FloorMod.fragileRain)) {
      if (r < 0.55) return BlockKind.fragile;
      if (r < 0.75) return BlockKind.normal;
      if (r < 0.9) return BlockKind.counter;
      return BlockKind.bonus;
    }
    if (mods.contains(FloorMod.iceRain)) {
      if (r < 0.55) return BlockKind.ice;
      if (r < 0.74) return BlockKind.normal;
      if (r < 0.9) return BlockKind.counter;
      return BlockKind.bonus;
    }
    // A rare helpful bomb appears in normal play.
    if (r < 0.05) return BlockKind.bomb;
    final heavy = mods.contains(FloorMod.heavy);
    if (r < (heavy ? 0.32 : 0.56)) return BlockKind.normal;
    if (r < 0.70) return BlockKind.wide;
    if (r < (heavy ? 0.76 : 0.82)) return BlockKind.light;
    if (r < 0.95) return BlockKind.counter;
    return BlockKind.bonus;
  }

  void update(double dt) {
    if (state != EngineState.swinging) return;
    _elapsed += dt;
    _phase += craneSpeed * dt;
    if (mods.contains(FloorMod.pulseSwing)) _pulsePhase += dt * 1.3;
    if (mods.contains(FloorMod.drift)) _driftPhase += dt * 0.9;
    if (_slowTimer > 0) _slowTimer -= dt;

    if (mods.contains(FloorMod.shrink)) {
      _baseHalf = math.max(0.12, _baseHalf - dt * 0.004);
      _supportL = math.max(_supportL, -_baseHalf);
      _supportR = math.min(_supportR, _baseHalf);
    }
    if (mods.contains(FloorMod.escalate)) {
      _speed += dt * 0.05;
    }

    if (hasDeadline) {
      _remaining -= dt;
      if (_remaining <= 0) {
        _remaining = 0;
        _topple();
        notifyListeners();
        return;
      }
    }

    final wm = windMax +
        blocks.length * 0.003 +
        (mods.contains(FloorMod.gusts) ? 0.10 : 0) +
        (mods.contains(FloorMod.escalate) ? _elapsed * 0.004 : 0);
    _windTimer -= dt;
    if (_windTimer <= 0) {
      _windTimer = mods.contains(FloorMod.gusts)
          ? 1.0 + _rng.nextDouble() * 1.2
          : 2.5 + _rng.nextDouble() * 2.5;
      _windTarget = (_rng.nextDouble() * 2 - 1) * wm;
    }
    final follow = mods.contains(FloorMod.gusts) ? 1.6 : 0.8;
    _windBias += (_windTarget - _windBias) * (dt * follow);

    if (mods.contains(FloorMod.quake)) _quakePhase += dt * 2.4;

    if (effectiveLean.abs() >= leanLimit) {
      _topple();
    } else if (goalType == GoalType.survive &&
        goal != null &&
        _elapsed >= goal!) {
      state = EngineState.won;
    }
    notifyListeners();
  }

  /// Release the carried module. Overlap is enforced; overhang is trimmed.
  void drop() {
    if (state != EngineState.swinging) return;
    final kind = _nextKind;
    final w = kind.halfW;
    final left = craneX - w;
    final right = craneX + w;

    final ovL = math.max(left, _supportL);
    final ovR = math.min(right, _supportR);
    final overlap = ovR - ovL;

    if (overlap <= _minOverlap) {
      // Missed the stack entirely.
      lastResult = DropResult.miss;
      _topple();
      notifyListeners();
      return;
    }

    final perfectTol = kind == BlockKind.fragile ? 0.035 : 0.055;
    final offset = (craneX - supportCentre).abs();
    late TowerBlock block;

    if (offset <= perfectTol) {
      // Perfect: keep full width, reward, gently widen support (capped at base).
      block = TowerBlock(x: craneX, halfW: w, kind: kind, perfect: true);
      combo++;
      perfectDrops++;
      if (combo > bestCombo) bestCombo = combo;
      _supportL = math.max(-_baseHalf, block.left);
      _supportR = math.min(_baseHalf, block.right);
      lastResult = DropResult.perfect;
      bonusCoins += 5 + combo;
    } else {
      // Trim the overhang; the tower narrows.
      final cx = (ovL + ovR) / 2;
      block = TowerBlock(x: cx, halfW: overlap / 2, kind: kind);
      combo = 0;
      _supportL = block.left;
      _supportR = block.right;
      lastResult = DropResult.trimmed;
    }

    if (kind == BlockKind.bonus) bonusCoins += 15;
    blocks.add(block);

    // Special module side-effects.
    if (kind == BlockKind.bomb) {
      // Detonates into a reinforced footing: widen support around its centre.
      final mid = block.x;
      _supportL = math.max(-_baseHalf, mid - _baseHalf);
      _supportR = math.min(_baseHalf, mid + _baseHalf);
    } else if (kind == BlockKind.ice) {
      // Slippery: the footing slides a touch toward the current lean.
      final slip = 0.03 * (effectiveLean.sign);
      _supportL += slip;
      _supportR += slip;
    }

    _nextKind = _afterKind;
    _afterKind = _rollKind();

    if (effectiveLean.abs() >= leanLimit) {
      _topple();
    } else {
      _checkWin();
    }
    notifyListeners();
  }

  void _checkWin() {
    final g = goal;
    if (g == null) return;
    switch (goalType) {
      case GoalType.height:
      case GoalType.limited:
        if (blocks.length >= g) state = EngineState.won;
        break;
      case GoalType.perfects:
        if (perfectDrops >= g) state = EngineState.won;
        break;
      case GoalType.survive:
        break; // handled in update()
    }
  }

  void _topple() => state = EngineState.over;

  /// Boost: cancel wind/drift and re-widen the support a little.
  void stabilise() {
    _windBias = 0;
    _windTarget = 0;
    _windTimer = 4;
    _driftPhase = 0;
    final mid = supportCentre;
    _supportL = math.max(-_baseHalf, mid - 0.16);
    _supportR = math.min(_baseHalf, mid + 0.16);
    notifyListeners();
  }

  /// Boost: slow the crane for a few seconds.
  void slowMo() {
    _slowTimer = 5;
    notifyListeners();
  }

  /// Boost: reinforce — widen the support back toward the full base.
  void widen() {
    final mid = supportCentre;
    _supportL = math.max(-_baseHalf, mid - _baseHalf);
    _supportR = math.min(_baseHalf, mid + _baseHalf);
    notifyListeners();
  }
}
