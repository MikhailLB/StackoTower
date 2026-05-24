// ignore_for_file: avoid_print
import 'dart:typed_data';

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
  const configHost   = 'https://stackotower.com';
  const configPath   = '/config.php';
  const privacyUrl   = 'https://stackotower.com/privacy-policy.html';
  const supportUrl   = 'https://stackotower.com/support.html';
  const gcdHost      = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';
  const appsflyerKey = 'smdnHeQshG7EiGiS97uNjk';
  const firebaseNum  = '871474779536';

  print('HOST : ${fmt(encode(configHost))}');
  print('PATH : ${fmt(encode(configPath))}');
  print('PRIV : ${fmt(encode(privacyUrl))}');
  print('SUPP : ${fmt(encode(supportUrl))}');
  print('GCD  : ${fmt(encode(gcdHost))}');
  print('AF   : ${fmt(encode(appsflyerKey))}');
  print('FB   : ${fmt(encode(firebaseNum))}');
}
