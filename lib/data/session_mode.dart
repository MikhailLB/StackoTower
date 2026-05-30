enum SessionMode {
  online,
  offline,
  pending;

  static SessionMode fromString(String? value) {
    switch (value) {
      case 'online':
        return SessionMode.online;
      case 'offline':
        return SessionMode.offline;
      default:
        return SessionMode.pending;
    }
  }

  String toStorageString() {
    switch (this) {
      case SessionMode.online:
        return 'online';
      case SessionMode.offline:
        return 'offline';
      case SessionMode.pending:
        return 'pending';
    }
  }
}
