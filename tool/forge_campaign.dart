// One-shot authoring tool: forges campaign lots 16-60 with verified
// solvability and prints them as Dart source for lib/game/route_level.dart.
//
// Run from the project root:  dart run tool/forge_campaign.dart
import 'dart:math' as math;

import 'package:stacko_tower/game/level_forge.dart';

const names = <String>[
  // Neon Harbor (16-30)
  'Dockside Twins', 'Crane Alley', 'Pier Gates', 'Cargo Rows', 'Harbor Cross',
  'Tide Lock', 'Ferry Yard', 'Buoy Field', 'Anchor Point', 'Salt Wharf',
  'Container Maze', 'Night Pier', 'Beacon Walk', 'Dry Dock', 'Harbor Master',
  // Skyline Heights (31-45)
  'Mezzanine', 'Steel Spine', 'Glass Court', 'Vent Shafts', 'Sky Lobby',
  'Twin Elevators', 'Girder Forest', 'Helipad Run', 'Cloud Deck', 'Antenna Row',
  'Penthouse Loop', 'Wind Brace', 'Observation Ring', 'Spire Base', 'Skyline Crown',
  // Crystal Megapolis (46-60)
  'Neon Plaza', 'Circuit Block', 'Hologram Square', 'Data Spine', 'Chrome Garden',
  'Prism Court', 'Quantum Yard', 'Lumen Bridge', 'Synth Market', 'Mirror District',
  'Pulse Avenue', 'Aurora Gate', 'Nova Junction', 'Zenith Field', 'Crystal Core',
];

(int, int, int) shape(int level) {
  if (level <= 22) return (6, 6 + (level % 2), 1 + (level - 16) ~/ 4);
  if (level <= 30) return (7, 7 + (level % 2), 2 + (level - 23) ~/ 4);
  if (level <= 38) return (8, 8 + (level % 2), 3 + (level - 31) ~/ 4);
  if (level <= 45) return (9, 8 + (level % 2), 4 + (level - 39) ~/ 4);
  if (level <= 52) return (9, 9 + (level % 2), 5 + (level - 46) ~/ 4);
  return (10, 9 + (level % 2), 5 + (level - 53) ~/ 4);
}

int reward(int level) => 520 + (level - 15) * 22;

bool isBorder(int i, int rows, int cols) {
  final r = i ~/ cols, c = i % cols;
  return r == 0 || c == 0 || r == rows - 1 || c == cols - 1;
}

int dist(int a, int b, int cols) =>
    (a ~/ cols - b ~/ cols).abs() + (a % cols - b % cols).abs();

Set<int> placeDominoes(math.Random rand, int rows, int cols, int count) {
  final walls = <int>{};
  var guard = 300;
  while (count > 0 && guard-- > 0) {
    final horizontal = rand.nextBool();
    final r = 1 + rand.nextInt(math.max(1, rows - 2 - (horizontal ? 0 : 1)));
    final c = 1 + rand.nextInt(math.max(1, cols - 2 - (horizontal ? 1 : 0)));
    final a = r * cols + c;
    final b = horizontal ? a + 1 : a + cols;
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

void main() {
  final buf = StringBuffer();
  for (var level = 16; level <= 60; level++) {
    final (rows, cols, dominoes) = shape(level);
    var found = false;
    for (var attempt = 0; attempt < 300 && !found; attempt++) {
      final rand = math.Random(level * 31337 + attempt * 1000003);
      final walls = placeDominoes(rand, rows, cols, dominoes);
      final solver = PathSolver(rows, cols, walls, budget: 150000);
      // Randomise corner order so starts vary across the campaign.
      final corners = <int>[
        0,
        cols - 1,
        (rows - 1) * cols,
        rows * cols - 1,
      ]..shuffle(rand);
      final borders = <int>[
        for (var i = 0; i < rows * cols; i++)
          if (!walls.contains(i) && isBorder(i, rows, cols)) i
      ];
      for (final s in corners.where((i) => !walls.contains(i))) {
        final exits = [
          ...borders.where((e) => e != s && solver.parityOk(s, e))
        ]..sort((a, b) => dist(b, s, cols).compareTo(dist(a, s, cols)));
        // Only probe the farthest few exits; cheap retries beat deep search.
        for (final e in exits.take(4)) {
          if (solver.solve(s, exit: e) != null) {
            emit(buf, level, rows, cols, walls, s, e);
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }
    if (!found) {
      buf.writeln('  // !!! level $level: FAILED TO FORGE');
    }
  }
  // ignore: avoid_print
  print(buf);
}

void emit(StringBuffer buf, int level, int rows, int cols, Set<int> walls,
    int start, int exit) {
  buf.writeln('  RouteLevel.grid(');
  buf.writeln('    levelNumber: $level,');
  buf.writeln("    name: '${names[level - 16]}',");
  buf.writeln('    coinReward: ${reward(level)},');
  buf.writeln('    start: (${start ~/ cols}, ${start % cols}),');
  buf.writeln('    exit: (${exit ~/ cols}, ${exit % cols}),');
  buf.writeln('    art: const [');
  for (var r = 0; r < rows; r++) {
    final row = StringBuffer();
    for (var c = 0; c < cols; c++) {
      row.write(walls.contains(r * cols + c) ? '#' : '.');
    }
    buf.writeln("      '$row',");
  }
  buf.writeln('    ],');
  buf.writeln('  ),');
}
