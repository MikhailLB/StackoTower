import '../../core/mask_util.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TODO: run tool/encode_creds.dart and paste byte arrays here
/// ════════════════════════════════════════════════════════════

String gateEndpointUrl() {
  // TODO: paste encoded host bytes here
  const h = <int>[];
  // TODO: paste encoded path bytes here
  const p = <int>[];
  if (h.isEmpty) return '';
  return unmask(h) + unmask(p);
}

// TODO: paste encoded GCD host mask here
const List<int> _gcdHostMask = [];

String gcdUrl(String appId, String deviceId) {
  if (_gcdHostMask.isEmpty) return '';
  final host = unmask(_gcdHostMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String uaChromeBuild() => '136.0.7103.93';
String uaSafariBuild() => '605.1.15';
