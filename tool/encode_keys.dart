// ignore_for_file: avoid_print

// ============================================================
// ENCODE KEYS — XOR encoding tool for StackoTower
// Run with: dart run tool/encode_keys.dart
// ⚠️ ALWAYS use dart run, never PowerShell loops (int overflow)
// ============================================================
//
// After running, paste the output byte arrays into:
//   lib/setup/keys_info.dart  — AppsFlyer key, Firebase project #
//   lib/setup/endpoint_info.dart — config endpoint URL
//   lib/core/net_client.dart — Chrome/WebKit version fragments

import 'dart:typed_data';

// === FILL IN YOUR VALUES HERE ===
const _appsFlyerKey = '3JFV6b7MExDmhS4HCirWNc';
const _firebaseProjectNumber = '53303715843';

// Config endpoint — split into host + path
const _configHost = 'https://sttackotower.com';
const _configPath = '/config.php';

// GCD endpoint parts
const _gcdHost = 'https://gcdsdk.appsflyer.com';
const _gcdPath = '/install_data/v4.0/';

// Chrome/WebKit User-Agent version fragments
const _chromeVersion = '131.0.6778.135';
const _webkitVersion = '537.36';
// ================================

// Seed: "stckotwr" — must match lib/helpers/cipher.dart
Uint8List _deriveKey() {
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

List<int> _encode(String s, Uint8List key) {
  final bytes = s.codeUnits;
  return List.generate(bytes.length, (i) => bytes[i] ^ key[i % key.length]);
}

void _printEncoded(String label, String value, Uint8List key) {
  final enc = _encode(value, key);
  print('$label: $enc');
}

void main() {
  final key = _deriveKey();
  print('=== StackoTower Encoded Keys ===\n');
  _printEncoded('appsFlyer key', _appsFlyerKey, key);
  _printEncoded('firebase project number', _firebaseProjectNumber, key);
  _printEncoded('config host', _configHost, key);
  _printEncoded('config path', _configPath, key);
  _printEncoded('gcd host', _gcdHost, key);
  _printEncoded('gcd path', _gcdPath, key);
  _printEncoded('chrome version', _chromeVersion, key);
  _printEncoded('webkit version', _webkitVersion, key);
  print('\n=== Done ===');
}
