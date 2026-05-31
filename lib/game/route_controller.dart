import 'package:flutter/foundation.dart';

import 'route_level.dart';

enum RouteStatus { routing, paused, complete }

/// Result of a single cell interaction, so the UI can play sounds/haptics.
enum RouteMove { ignored, paved, retracted, completed }

/// Pure-Dart logic for a Site Paver round. The player builds one continuous
/// path (no game engine). The UI listens to this [ChangeNotifier].
class RouteController extends ChangeNotifier {
  RouteController(this.level) : _path = <int>[level.startIndex];

  final RouteLevel level;

  final List<int> _path;
  RouteStatus _status = RouteStatus.routing;

  int get rows => level.rows;
  int get cols => level.cols;
  RouteStatus get status => _status;
  bool get isRouting => _status == RouteStatus.routing;

  List<int> get path => List.unmodifiable(_path);
  int get head => _path.last;
  int get pavedCount => _path.length;
  int get plotCount => level.plotCount;

  bool isPaved(int r, int c) => _path.contains(level.index(r, c));
  bool isHead(int r, int c) => head == level.index(r, c);
  bool isStart(int r, int c) => level.startIndex == level.index(r, c);
  bool isExit(int r, int c) => level.exitIndex == level.index(r, c);

  /// Order in which a cell was paved (1-based), or 0 if not paved.
  int pavedOrder(int r, int c) {
    final i = _path.indexOf(level.index(r, c));
    return i < 0 ? 0 : i + 1;
  }

  /// Try to move the road head to cell (r,c). Handles extend & retract.
  RouteMove enter(int r, int c) {
    if (!isRouting) return RouteMove.ignored;
    if (r < 0 || c < 0 || r >= rows || c >= cols) return RouteMove.ignored;
    if (level.isWall(r, c)) return RouteMove.ignored;

    final target = level.index(r, c);
    if (target == head) return RouteMove.ignored;

    // Drag back onto the previous cell → retract one step.
    if (_path.length >= 2 && target == _path[_path.length - 2]) {
      _path.removeLast();
      notifyListeners();
      return RouteMove.retracted;
    }

    // Must be orthogonally adjacent to the current head and unused.
    final hr = head ~/ cols;
    final hc = head % cols;
    if ((hr - r).abs() + (hc - c).abs() != 1) return RouteMove.ignored;
    if (_path.contains(target)) return RouteMove.ignored;

    _path.add(target);
    if (target == level.exitIndex && _path.length == plotCount) {
      _status = RouteStatus.complete;
      notifyListeners();
      return RouteMove.completed;
    }
    notifyListeners();
    return RouteMove.paved;
  }

  void undo() {
    if (!isRouting) return;
    if (_path.length > 1) {
      _path.removeLast();
      notifyListeners();
    }
  }

  void reset() {
    _path
      ..clear()
      ..add(level.startIndex);
    _status = RouteStatus.routing;
    notifyListeners();
  }

  void pause() {
    if (_status != RouteStatus.routing) return;
    _status = RouteStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != RouteStatus.paused) return;
    _status = RouteStatus.routing;
    notifyListeners();
  }

  /// Mark the round complete (used by the Skip Pass power-up).
  void forceComplete() {
    _status = RouteStatus.complete;
    notifyListeners();
  }
}
