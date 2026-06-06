import 'package:flutter_test/flutter_test.dart';
import 'package:fortress_blitz/game/route_level.dart';

/// Backtracking Hamiltonian-path solver with Warnsdorff ordering.
/// Returns a covering path from [start] to [exit] (exit == null → any end),
/// or null if none exists.
class _Solver {
  _Solver(this.rows, this.cols, this.walls);
  final int rows;
  final int cols;
  final Set<int> walls;

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
    _budget = 12000000;
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

  int _degree(int cell, List<bool> visited) => _neighbours(cell, visited).length;

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
      for (final e in exits) {
        if (solve(s, exit: e) != null) return (s, e);
      }
    }
    return null;
  }
}

void main() {
  test('every lot is solvable from its authored start to exit', () {
    expect(routeLevels, isNotEmpty);
    final failures = <String>[];
    for (final level in routeLevels) {
      final solver = _Solver(level.rows, level.cols, level.walls);
      final path = solver.solve(level.startIndex, exit: level.exitIndex);
      if (path == null) {
        final any = solver.findAny();
        final hint = any == null
            ? 'no solvable endpoints found (adjust walls)'
            : 'try start=(${any.$1 ~/ level.cols},${any.$1 % level.cols}) '
                'exit=(${any.$2 ~/ level.cols},${any.$2 % level.cols})';
        // ignore: avoid_print
        print('Lot ${level.levelNumber} "${level.name}": $hint');
        failures.add('Lot ${level.levelNumber} "${level.name}": $hint');
      } else if (path.length != level.plotCount) {
        failures.add('Lot ${level.levelNumber}: path covers '
            '${path.length}/${level.plotCount}');
      }
    }
    expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
  });

  test('level numbers are sequential', () {
    for (var i = 0; i < routeLevels.length; i++) {
      expect(routeLevels[i].levelNumber, i + 1);
    }
  });
}
