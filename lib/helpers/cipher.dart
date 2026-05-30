import 'dart:typed_data';

// ============================================================
// CIPHER — XOR string deobfuscator
// ============================================================
// Seed: "stckotwr" — unique to this project (StackoTower)
// To change: update _deriveKey() parts array, re-run encode_keys.dart
// ============================================================

Uint8List _deriveKey() {
  // Seed phrase: "stckotwr"
  // ASCII: s=115, t=116, c=99, k=107, o=111, t=116, w=119, r=114
  const parts = <int>[115, 116, 99, 107, 111, 116, 119, 114];

  final seed = parts.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
  final key = Uint8List(16);
  var v = seed;
  for (var i = 0; i < key.length; i++) {
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    key[i] = v & 0xFF;
  }
  return key;
}

final _xk = _deriveKey();

/// Decodes an XOR-encoded byte list back to a plain string.
String k(List<int> data) {
  final out = Uint8List(data.length);
  for (var i = 0; i < data.length; i++) {
    out[i] = data[i] ^ _xk[i % _xk.length];
  }
  return String.fromCharCodes(out);
}
