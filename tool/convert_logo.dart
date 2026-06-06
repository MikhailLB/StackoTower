import 'dart:io';
import 'package:image/image.dart' as img;

/// Converts logo.webp → logo.png for flutter_launcher_icons.
void main() {
  final webpBytes = File('assets/logo.webp').readAsBytesSync();
  final decoded = img.decodeWebP(webpBytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode assets/logo.webp');
    exit(1);
  }
  final outPath = 'assets/logo.png';
  File(outPath).writeAsBytesSync(img.encodePng(decoded));
  stdout.writeln('Wrote $outPath (${decoded.width}x${decoded.height})');
}
