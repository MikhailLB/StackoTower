/// A "Site Paver" route puzzle: pave one continuous road that visits every
/// open plot exactly once, starting at [startIndex] and finishing at
/// [exitIndex]. Some lots contain obstacle blocks ([walls]) you must route
/// around.
///
/// Two ways to build a level:
///  * [RouteLevel.open] — a plain open rectangle (solved by the snake path).
///  * [RouteLevel.grid] — an authored lot with obstacle blocks; the solvability
///    of every built-in lot is proven by the Hamiltonian solver in
///    `test/route_level_test.dart`.
class RouteLevel {
  RouteLevel._({
    required this.levelNumber,
    required this.name,
    required this.rows,
    required this.cols,
    required this.coinReward,
    required this.walls,
    required this.startIndex,
    required this.exitIndex,
  });

  factory RouteLevel.open({
    required int levelNumber,
    required String name,
    required int rows,
    required int cols,
    required int coinReward,
  }) {
    // Snake from (0,0) ends at the right corner when rows is odd, else left.
    final exitC = rows.isOdd ? cols - 1 : 0;
    return RouteLevel._(
      levelNumber: levelNumber,
      name: name,
      rows: rows,
      cols: cols,
      coinReward: coinReward,
      walls: const <int>{},
      startIndex: 0,
      exitIndex: (rows - 1) * cols + exitC,
    );
  }

  /// Authored lot. [art] rows use `#` for an obstacle block and any other
  /// character for open floor. [start]/[exit] are (row, col) coordinates.
  factory RouteLevel.grid({
    required int levelNumber,
    required String name,
    required int coinReward,
    required List<String> art,
    required (int, int) start,
    required (int, int) exit,
  }) {
    final rows = art.length;
    final cols = art.first.length;
    assert(art.every((r) => r.length == cols),
        'Lot $levelNumber "$name": ragged rows');
    final walls = <int>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (art[r][c] == '#') walls.add(r * cols + c);
      }
    }
    final si = start.$1 * cols + start.$2;
    final ei = exit.$1 * cols + exit.$2;
    assert(!walls.contains(si), 'Lot $levelNumber: start on a wall');
    assert(!walls.contains(ei), 'Lot $levelNumber: exit on a wall');
    return RouteLevel._(
      levelNumber: levelNumber,
      name: name,
      rows: rows,
      cols: cols,
      coinReward: coinReward,
      walls: walls,
      startIndex: si,
      exitIndex: ei,
    );
  }

  final int levelNumber;
  final String name;
  final int rows;
  final int cols;
  final int coinReward;
  final Set<int> walls;
  final int startIndex;
  final int exitIndex;

  int get startR => startIndex ~/ cols;
  int get startC => startIndex % cols;
  int get exitR => exitIndex ~/ cols;
  int get exitC => exitIndex % cols;

  int index(int r, int c) => r * cols + c;
  bool isWall(int r, int c) => walls.contains(index(r, c));
  bool isWallIndex(int i) => walls.contains(i);

  /// Open plots that must be paved.
  int get plotCount => rows * cols - walls.length;
}

/// All Site Paver lots, ordered by difficulty. Early lots are open; later lots
/// add obstacle blocks. Every lot is proven solvable by the test suite.
final List<RouteLevel> routeLevels = <RouteLevel>[
  RouteLevel.open(levelNumber: 1, name: 'Foundation Lot', rows: 3, cols: 3, coinReward: 50),
  RouteLevel.open(levelNumber: 2, name: 'Corner Plot', rows: 4, cols: 4, coinReward: 70),
  RouteLevel.open(levelNumber: 3, name: 'Service Road', rows: 4, cols: 5, coinReward: 90),
  RouteLevel.grid(
    levelNumber: 4,
    name: 'First Pillar',
    coinReward: 110,
    start: (0, 0),
    exit: (4, 4),
    art: const [
      '.....',
      '..#..',
      '..#..',
      '.....',
      '.....',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 5,
    name: 'Twin Posts',
    coinReward: 130,
    start: (0, 0),
    exit: (4, 5),
    art: const [
      '......',
      '......',
      '..##..',
      '......',
      '......',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 6,
    name: 'Gate Posts',
    coinReward: 150,
    start: (0, 0),
    exit: (2, 5),
    art: const [
      '......',
      '......',
      '.##...',
      '...##.',
      '......',
      '......',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 7,
    name: 'Loading Bay',
    coinReward: 180,
    start: (0, 0),
    exit: (5, 6),
    art: const [
      '.......',
      '.......',
      '.##....',
      '....##.',
      '.......',
      '.......',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 8,
    name: 'Central Mast',
    coinReward: 210,
    start: (0, 0),
    exit: (6, 6),
    art: const [
      '.......',
      '...#...',
      '...#...',
      '.......',
      '...#...',
      '...#...',
      '.......',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 9,
    name: 'Depot Blocks',
    coinReward: 240,
    start: (0, 0),
    exit: (2, 7),
    art: const [
      '........',
      '........',
      '..##.##.',
      '........',
      '........',
      '........',
      '........',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 10,
    name: 'Wide Terminal',
    coinReward: 280,
    start: (0, 0),
    exit: (6, 8),
    art: const [
      '.........',
      '.........',
      '..##.##..',
      '.........',
      '....##...',
      '.........',
      '.........',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 11,
    name: 'Four Corners',
    coinReward: 320,
    start: (0, 0),
    exit: (2, 7),
    art: const [
      '........',
      '........',
      '..##.##.',
      '........',
      '........',
      '..##.##.',
      '........',
      '........',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 12,
    name: 'Harbor Works',
    coinReward: 360,
    start: (0, 0),
    exit: (7, 8),
    art: const [
      '.........',
      '.........',
      '..##.##..',
      '.........',
      '.........',
      '..##.##..',
      '.........',
      '.........',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 13,
    name: 'Grand Avenue',
    coinReward: 420,
    start: (0, 0),
    exit: (7, 8),
    art: const [
      '..........',
      '..##..##..',
      '..........',
      '..........',
      '....##....',
      '..........',
      '..........',
      '..##..##..',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 14,
    name: 'Tower District',
    coinReward: 460,
    start: (0, 0),
    exit: (8, 8),
    art: const [
      '.........',
      '.........',
      '..##.##..',
      '.........',
      '.........',
      '.........',
      '..##.##..',
      '.........',
      '.........',
    ],
  ),
  RouteLevel.grid(
    levelNumber: 15,
    name: 'Megastructure',
    coinReward: 520,
    start: (0, 8),
    exit: (8, 0),
    art: const [
      '.........',
      '.........',
      '..##.##..',
      '.........',
      '....##...',
      '.........',
      '..##.##..',
      '.........',
      '.........',
    ],
  ),
];

RouteLevel routeLevelByNumber(int number) => routeLevels.firstWhere(
      (l) => l.levelNumber == number,
      orElse: () => routeLevels.first,
    );
