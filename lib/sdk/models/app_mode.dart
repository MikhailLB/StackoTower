enum AppMode {
  web,
  game,
  fresh;

  String toKey() {
    switch (this) {
      case AppMode.web:   return 'web';
      case AppMode.game:  return 'game';
      case AppMode.fresh: return 'fresh';
    }
  }

  static AppMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return AppMode.web;
      case 'game':
      case 'arcade':
        return AppMode.game;
      default:
        return AppMode.fresh;
    }
  }
}
