import 'dart:typed_data';

// Lightweight byte-array obfuscation for embedded configuration values.
// The keystream is derived from a project-specific phrase via djb2 + a
// xorshift32 generator, then folded with the byte position. Encode and
// decode are the same operation.
const _phrase = <int>[
  0x73, 0x74, 0x6B, 0x2D, 0x74, 0x6F, 0x77, 0x65, 0x72, 0x2D,
  0x63, 0x69, 0x70, 0x68, 0x65, 0x72, 0x2D, 0x32, 0x30, 0x32, 0x36,
];

const _span = 96;

Uint8List _keystream() {
  var h = 5381;
  for (final b in _phrase) {
    h = (((h * 33) & 0xFFFFFFFF) ^ b) & 0xFFFFFFFF;
  }
  var state = h == 0 ? 0x9E3779B9 : h;
  final out = Uint8List(_span);
  for (var i = 0; i < _span; i++) {
    state ^= (state << 13) & 0xFFFFFFFF;
    state &= 0xFFFFFFFF;
    state ^= state >> 17;
    state ^= (state << 5) & 0xFFFFFFFF;
    state &= 0xFFFFFFFF;
    out[i] = ((state >> 11) ^ ((i * 7 + 1) & 0xFF)) & 0xFF;
  }
  return out;
}

final Uint8List _ks = _keystream();

String reveal(List<int> raw) {
  if (raw.isEmpty) return '';
  final out = Uint8List(raw.length);
  for (var i = 0; i < raw.length; i++) {
    out[i] = raw[i] ^ _ks[i % _span] ^ (i & 0x3F);
  }
  return String.fromCharCodes(out);
}
