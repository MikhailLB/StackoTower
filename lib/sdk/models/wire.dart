// Wire-level models: launch routing mode + decoded remote response.

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

class RemoteReply {
  final bool granted;
  final String? destination;
  final String? note;
  final int? expiresAt;

  const RemoteReply._({
    required this.granted,
    this.destination,
    this.note,
    this.expiresAt,
  });

  factory RemoteReply.fromMap(Map<String, dynamic> raw) {
    final granted = (raw['ok'] as bool?)        ??
                    (raw['granted'] as bool?)    ??
                    (raw['accepted'] as bool?)   ??
                    false;

    final destination = raw['url'] as String?        ??
                        raw['link'] as String?       ??
                        raw['target'] as String?     ??
                        raw['destination'] as String?;

    final note = raw['message'] as String? ??
                 raw['note'] as String?    ??
                 raw['reason'] as String?;

    final dynamic ttl = raw['expires'] ?? raw['expires_at'] ?? raw['valid_until'];
    int? expires;
    if (ttl is int) {
      expires = ttl;
    } else if (ttl is num) {
      expires = ttl.toInt();
    } else if (ttl is String) {
      expires = int.tryParse(ttl);
    }

    return RemoteReply._(
      granted: granted,
      destination: destination,
      note: note,
      expiresAt: expires,
    );
  }

  factory RemoteReply.declined(String reason) =>
      RemoteReply._(granted: false, note: reason);
}
