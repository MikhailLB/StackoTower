import 'dart:io';
import 'package:image/image.dart' as img;

/// Converts stacko_icon.webp → stacko_icon.png for flutter_launcher_icons.
void main() {
  final webpBytes = File('assets/stacko_icon.webp').readAsBytesSync();
  final decoded = img.decodeWebP(webpBytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode assets/stacko_icon.webp');
    exit(1);
  }
  final outPath = 'assets/stacko_icon.png';
  File(outPath).writeAsBytesSync(img.encodePng(decoded));
  stdout.writeln('Wrote $outPath (${decoded.width}x${decoded.height})');
}
