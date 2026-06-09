import 'package:flutter_test/flutter_test.dart';
import 'package:stacko_tower/game/level_forge.dart';
import 'package:stacko_tower/game/route_level.dart';

void main() {
  test('every lot is solvable from its authored start to exit', () {
    expect(routeLevels, isNotEmpty);
    final failures = <String>[];
    for (final level in routeLevels) {
      final solver = PathSolver(level.rows, level.cols, level.walls);
      final path = solver.solve(level.startIndex, exit: level.exitIndex);
      if (path == null) {
        final any = solver.findAny();
        final hint = any == null
            ? 'no solvable endpoints found (adjust walls)'
            : 'try start=(${any.$1 ~/ level.cols},${any.$1 % level.cols}) '
                'exit=(${any.$2 ~/ level.cols},${any.$2 % level.cols})';
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

  test('districts cover the whole campaign', () {
    expect(districts.first.firstLevel, 1);
    expect(districts.last.lastLevel, routeLevels.length);
    for (var i = 1; i < districts.length; i++) {
      expect(districts[i].firstLevel, districts[i - 1].lastLevel + 1);
    }
    for (final level in routeLevels) {
      expect(districtOf(level.levelNumber).contains(level.levelNumber), isTrue);
    }
  });

  test('endless forge produces solvable lots for the first 40 stages', () {
    for (var stage = 0; stage < 40; stage++) {
      final level = LevelForge.endless(stage);
      final solver = PathSolver(level.rows, level.cols, level.walls);
      final path = solver.solve(level.startIndex, exit: level.exitIndex);
      expect(path, isNotNull, reason: 'endless stage $stage unsolvable');
      expect(path!.length, level.plotCount);
    }
  });

  test('daily forge is deterministic and solvable across a month', () {
    for (var day = 1; day <= 31; day++) {
      final date = DateTime(2026, 7, day);
      final a = LevelForge.daily(date);
      final b = LevelForge.daily(date);
      expect(a.walls, b.walls, reason: 'daily must be deterministic');
      expect(a.startIndex, b.startIndex);
      expect(a.exitIndex, b.exitIndex);
      final solver = PathSolver(a.rows, a.cols, a.walls);
      final path = solver.solve(a.startIndex, exit: a.exitIndex);
      expect(path, isNotNull, reason: 'daily $date unsolvable');
    }
  });
}
