import '../../core/mask_util.dart';

String remoteUrl() {
  const h = [14, 128, 91, 25, 227, 242, 212, 39, 238, 12, 118, 227, 45, 48, 143, 133, 181, 54, 236, 240, 169, 195, 21];
  const p = [73, 151, 64, 7, 246, 161, 156, 38, 237, 16, 103];
  return unmask(h) + unmask(p);
}

const List<int> _syncHostMask = [14, 128, 91, 25, 227, 242, 212, 39, 250, 27, 115, 243, 34, 52, 213, 139, 178, 35, 237, 184, 166, 213, 29, 1, 187, 32, 237, 47, 244, 6, 90, 17, 162, 104, 233, 7, 100, 12, 140, 3, 36, 74, 19, 47, 135, 103, 74];

String syncUrl(String appId, String deviceId) {
  final host = unmask(_syncHostMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String chromeBuild() => '136.0.7103.93';
String safariBuild() => '605.1.15';
