/// Persisted decision about how the app should route on each launch.
///
/// - [web]     → open the WebView (returning user with a saved URL).
/// - [game]    → no destination granted (organic / unattributed user).
///              The white-part game was removed, so this now lands on
///              NoSignalScreen; the value is kept for storage compatibility
///              and to keep retrying web recovery on subsequent launches.
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
