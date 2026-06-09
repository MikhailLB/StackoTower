import 'dart:math' as math;

import 'route_level.dart';

/// Backtracking Hamiltonian-path solver with Warnsdorff ordering.
/// Shared by the level generator (runtime) and the solvability test suite.
class PathSolver {
  PathSolver(this.rows, this.cols, this.walls, {this.budget = 12000000});

  final int rows;
  final int cols;
  final Set<int> walls;
  final int budget;

  late final int total = rows * cols - walls.length;
  int _budget = 0;

  late final int _b = () {
    var b = 0;
    for (var i = 0; i < rows * cols; i++) {
      if (!walls.contains(i) && ((i ~/ cols) + (i % cols)).isEven) b++;
    }
    return b;
  }();
  int get _w => total - _b;

  int _color(int i) => ((i ~/ cols) + (i % cols)).isEven ? 0 : 1;

  /// Necessary colour-parity condition for a Hamiltonian path start->exit.
  bool parityOk(int start, int exit) {
    final sc = _color(start), ec = _color(exit);
    if (total.isEven) {
      return _b == _w && sc != ec;
    }
    final majority = _b > _w ? 0 : 1;
    return (_b - _w).abs() == 1 && sc == majority && ec == majority;
  }

  List<int>? solve(int start, {int? exit}) {
    if (walls.contains(start)) return null;
    if (exit != null && !parityOk(start, exit)) return null;
    _budget = budget;
    final visited = List<bool>.filled(rows * cols, false);
    final path = <int>[start];
    visited[start] = true;
    if (_dfs(start, visited, path, exit)) return path;
    return null;
  }

  bool _dfs(int cur, List<bool> visited, List<int> path, int? exit) {
    if (_budget-- <= 0) return false;
    if (path.length == total) {
      return exit == null || cur == exit;
    }
    final nbrs = _neighbours(cur, visited);
    // Warnsdorff: try the neighbour with the fewest onward moves first.
    nbrs.sort((a, b) => _degree(a, visited).compareTo(_degree(b, visited)));
    for (final n in nbrs) {
      visited[n] = true;
      path.add(n);
      if (_dfs(n, visited, path, exit)) return true;
      path.removeLast();
      visited[n] = false;
    }
    return false;
  }

  List<int> _neighbours(int cell, List<bool> visited) {
    final r = cell ~/ cols, c = cell % cols;
    final out = <int>[];
    void add(int rr, int cc) {
      if (rr < 0 || cc < 0 || rr >= rows || cc >= cols) return;
      final i = rr * cols + cc;
      if (walls.contains(i) || visited[i]) return;
      out.add(i);
    }

    add(r - 1, c);
    add(r + 1, c);
    add(r, c - 1);
    add(r, c + 1);
    return out;
  }

  int _degree(int cell, List<bool> visited) =>
      _neighbours(cell, visited).length;

  bool _isBorder(int i) {
    final r = i ~/ cols, c = i % cols;
    return r == 0 || c == 0 || r == rows - 1 || c == cols - 1;
  }

  int _dist(int a, int b) =>
      (a ~/ cols - b ~/ cols).abs() + (a % cols - b % cols).abs();

  /// Find a solvable (start, exit) pair, preferring a corner start and the
  /// farthest border exit (so endpoints look natural).
  (int, int)? findAny() {
    final borders = <int>[
      for (var i = 0; i < rows * cols; i++)
        if (!walls.contains(i) && _isBorder(i)) i
    ];
    final starts = <int>[
      0,
      cols - 1,
      (rows - 1) * cols,
      rows * cols - 1,
    ].where((i) => !walls.contains(i));
    for (final s in starts) {
      final exits = [...borders.where((e) => e != s && parityOk(s, e))]
        ..sort((a, b) => _dist(b, s).compareTo(_dist(a, s)));
      // Probing only the farthest few exits keeps generation fast; failed
      // lots are simply re-rolled with a fresh seed.
      for (final e in exits.take(6)) {
        if (solve(s, exit: e) != null) return (s, e);
      }
    }
    return null;
  }
}

/// Procedurally forges solvable Site Paver lots: deterministic per seed, so
/// the same seed always yields the same lot (used by Daily Blueprint), and
/// an escalating series powers the Endless Shift mode.
class LevelForge {
  LevelForge._();

  /// (rows, cols, wall dominoes) per endless difficulty tier.
  static const List<(int, int, int)> _tiers = [
    (4, 4, 0),
    (5, 5, 1),
    (5, 6, 1),
    (6, 6, 2),
    (6, 7, 2),
    (7, 7, 3),
    (7, 8, 3),
    (8, 8, 4),
    (8, 9, 4),
    (9, 9, 5),
  ];

  static int endlessTier(int stage) =>
      math.min(stage ~/ 3, _tiers.length - 1);

  static int endlessReward(int stage) => 30 + endlessTier(stage) * 15;

  /// Endless level for the given stage (0-based). Difficulty ramps every
  /// 3 stages; lots keep varying forever thanks to the stage seed.
  static RouteLevel endless(int stage) {
    final (rows, cols, dominoes) = _tiers[endlessTier(stage)];
    return _forge(
      seed: 0x5EED + stage * 7919,
      rows: rows,
      cols: cols,
      dominoes: dominoes,
      levelNumber: stage + 1,
      name: 'Shift ${stage + 1}',
      coinReward: endlessReward(stage),
    );
  }

  /// Today's Daily Blueprint: one fixed challenging lot per calendar day.
  static RouteLevel daily(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    return _forge(
      seed: seed,
      rows: 7,
      cols: 7,
      dominoes: 3,
      levelNumber: seed,
      name: 'Blueprint ${date.day}.${date.month}',
      coinReward: 150,
    );
  }

  static const int dailyReward = 150;

  /// Builds a solvable lot. Walls are placed as dominoes (parity-neutral),
  /// then a start/exit pair is searched; on failure the seed advances.
  static RouteLevel _forge({
    required int seed,
    required int rows,
    required int cols,
    required int dominoes,
    required int levelNumber,
    required String name,
    required int coinReward,
  }) {
    for (var attempt = 0; attempt < 40; attempt++) {
      final rand = math.Random(seed + attempt * 1000003);
      final walls = _placeDominoes(rand, rows, cols, dominoes);
      final solver = PathSolver(rows, cols, walls, budget: 150000);
      final endpoints = solver.findAny();
      if (endpoints != null) {
        return RouteLevel.raw(
          levelNumber: levelNumber,
          name: name,
          rows: rows,
          cols: cols,
          coinReward: coinReward,
          walls: walls,
          startIndex: endpoints.$1,
          exitIndex: endpoints.$2,
        );
      }
      // Retry with fewer walls if the lot keeps coming out unsolvable.
      if (attempt == 25 && dominoes > 0) dominoes--;
    }
    // Guaranteed fallback: an open lot is always solvable by the snake path.
    return RouteLevel.open(
      levelNumber: levelNumber,
      name: name,
      rows: rows,
      cols: cols,
      coinReward: coinReward,
    );
  }

  /// Random non-touching dominoes kept off the border so the lot stays
  /// connected in practice (final solvability is still verified).
  static Set<int> _placeDominoes(
    math.Random rand,
    int rows,
    int cols,
    int count,
  ) {
    final walls = <int>{};
    var guard = 200;
    while (count > 0 && guard-- > 0) {
      final horizontal = rand.nextBool();
      final r = 1 + rand.nextInt(math.max(1, rows - 2 - (horizontal ? 0 : 1)));
      final c = 1 + rand.nextInt(math.max(1, cols - 2 - (horizontal ? 1 : 0)));
      final a = r * cols + c;
      final b = horizontal ? a + 1 : a + cols;
      // Keep a one-cell gap around existing walls.
      final tooClose = walls.any((w) {
        final wr = w ~/ cols, wc = w % cols;
        for (final cell in [a, b]) {
          final cr = cell ~/ cols, cc = cell % cols;
          if ((wr - cr).abs() <= 1 && (wc - cc).abs() <= 1) return true;
        }
        return false;
      });
      if (tooClose) continue;
      walls
        ..add(a)
        ..add(b);
      count--;
    }
    return walls;
  }
}
