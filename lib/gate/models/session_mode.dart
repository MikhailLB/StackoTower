/// Persisted decision about how the app should route on each launch.
///
/// - [web]     → open the WebView (returning user with a saved URL).
/// - [game]    → open the white-part game (organic / unattributed user).
/// - [fresh]   → no decision yet; full attribution pipeline will run.
enum SessionMode {
  web,
  game,
  fresh;

  String toKey() {
    switch (this) {
      case SessionMode.web:   return 'web';
      case SessionMode.game:  return 'game';
      case SessionMode.fresh: return 'fresh';
    }
  }

  static SessionMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return SessionMode.web;
      case 'game':
      case 'arcade':
        return SessionMode.game;
      default:
        return SessionMode.fresh;
    }
  }
}
