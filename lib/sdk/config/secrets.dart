import '../../core/codec.dart';

// Embedded configuration values. Byte arrays are obfuscated with core/codec.

String remoteUrl() {
  const a = [205, 88, 231, 23, 193, 184, 36, 244, 44, 149, 252, 218, 197, 213, 245, 239, 238, 238, 174, 40, 90, 181, 159];
  const b = [138, 79, 252, 9, 212, 235, 108, 245, 47, 137, 237];
  return reveal(a) + reveal(b);
}

const List<int> _syncMask = [205, 88, 231, 23, 193, 184, 36, 244, 56, 130, 249, 202, 202, 209, 175, 225, 233, 251, 175, 96, 85, 163, 151, 92, 248, 207, 115, 187, 34, 62, 3, 29, 173, 8, 59, 191, 233, 242, 184, 236, 65, 22, 136, 122, 221, 168, 72];

String syncUrl(String appId, String deviceId) {
  final host = reveal(_syncMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String analyticsKey() {
  const v = [214, 65, 247, 9, 250, 231, 90, 168, 55, 166, 170, 252, 199, 253, 232, 211, 160, 188, 169, 72, 83, 177];
  return reveal(v);
}

String cloudMsgId() {
  const v = [157, 27, 162, 83, 133, 182, 60, 236, 102, 212, 174, 143];
  return reveal(v);
}

const List<int> _privacyMask = [205, 88, 231, 23, 193, 184, 36, 244, 44, 149, 252, 218, 197, 213, 245, 239, 238, 238, 174, 40, 90, 181, 159, 1, 166, 222, 117, 160, 108, 52, 20, 67, 169, 6, 59, 186, 213, 239, 247, 240, 84, 84, 146];
const List<int> _supportMask = [205, 88, 231, 23, 193, 184, 36, 244, 44, 149, 252, 218, 197, 213, 245, 239, 238, 238, 174, 40, 90, 181, 159, 1, 165, 217, 108, 166, 98, 37, 25, 64, 177, 29, 58, 191];

String get privacyLink => reveal(_privacyMask);
String get supportLink  => reveal(_supportMask);

String chromeBuild() => '136.0.7103.93';
String safariBuild() => '605.1.15';
