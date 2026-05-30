import '../helpers/cipher.dart';

String resolveEndpoint() {
  const h = <int>[230, 219, 200, 53, 233, 241, 135, 238, 21, 211, 32, 156, 145, 40, 175, 141, 225, 216, 217, 55, 180, 168, 199, 172];
  const p = <int>[161, 204, 211, 43, 252, 162, 207, 239, 22, 207, 36];
  return k(h) + k(p);
}
