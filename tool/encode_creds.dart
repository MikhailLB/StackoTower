// ignore_for_file: avoid_print
// Run: dart run tool/encode_creds.dart
// Paste the printed byte arrays into lib/gate/config/
import 'dart:typed_data';

// ⚠️ Seed MUST match lib/core/mask_util.dart _seedBytes
// Current seed: "stacko.tower.v1"
const _seedBytes = <int>[
  0x73, 0x74, 0x61, 0x63, 0x6B, 0x6F, 0x2E, 0x74,
  0x6F, 0x77, 0x65, 0x72, 0x2E, 0x76, 0x31,
];

Uint8List _deriveKeyStream(int size) {
  var hash = 0x811C9DC5;
  for (final b in _seedBytes) {
    hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  final out = Uint8List(size);
  var state = hash == 0 ? 0xDEADBEEF : hash;
  for (var i = 0; i < size; i++) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    out[i] = (state >> 7) & 0xFF;
  }
  return out;
}

final _stream = _deriveKeyStream(64);

List<int> encode(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    out.add(s.codeUnitAt(i) ^ _stream[i % _stream.length]);
  }
  return out;
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  // ── TODO: fill these before running ────────────────────────────────
  const configHost   = 'https://TODO_YOUR_DOMAIN.com';
  const configPath   = '/config.php';
  const privacyUrl   = 'https://TODO_YOUR_DOMAIN.com/privacy-policy.html';
  const supportUrl   = 'https://TODO_YOUR_DOMAIN.com/support.html';
  const gcdHost      = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';
  // AppsFlyer Dev Key (Dashboard → App Settings → Dev Key)
  const appsflyerKey = 'TODO_APPSFLYER_DEV_KEY';
  // Firebase Project Number (google-services.json → "project_number")
  const firebaseNum  = 'TODO_FIREBASE_PROJECT_NUMBER';
  // ───────────────────────────────────────────────────────────────────

  print('// endpoint_vault.dart');
  print('HOST : ${fmt(encode(configHost))}');
  print('PATH : ${fmt(encode(configPath))}');
  print('GCD  : ${fmt(encode(gcdHost))}');
  print('');
  print('// brand_links.dart');
  print('PRIV : ${fmt(encode(privacyUrl))}');
  print('SUPP : ${fmt(encode(supportUrl))}');
  print('');
  print('// signal_keys.dart');
  print('AF_KEY : ${fmt(encode(appsflyerKey))}');
  print('FB_NUM : ${fmt(encode(firebaseNum))}');
}
