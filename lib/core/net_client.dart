import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../helpers/cipher.dart';

// XOR-encoded Chrome version fragment
String get _cv => k(const <int>[191, 156, 141, 107, 170, 229, 158, 246, 81, 159, 122, 204, 193, 118]);

// XOR-encoded WebKit version fragment
String get _sv => k(const <int>[187, 156, 139, 107, 169, 253]);

class AppNetClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  String? _userAgent;

  Future<void> init() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        final sdk = a.version.sdkInt;
        final model = a.model;
        final brand = a.brand;
        final build = a.display.isNotEmpty ? a.display : a.id;
        final cv = _cv.isNotEmpty ? _cv : '131.0.6778.135';
        _userAgent = 'Mozilla/5.0 (Linux; Android $sdk; $brand $model '
            'Build/$build) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/$cv Mobile Safari/537.36';
      } else {
        final i = await info.iosInfo;
        final ver = i.systemVersion.replaceAll('.', '_');
        final sv = _sv.isNotEmpty ? _sv : '537.36';
        _userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS $ver like Mac OS X) '
            'AppleWebKit/$sv (KHTML, like Gecko) '
            'Version/${i.systemVersion} Mobile/15E148 Safari/$sv';
      }
    } catch (_) {
      final cv = _cv.isNotEmpty ? _cv : '131.0.6778.135';
      final sv = _sv.isNotEmpty ? _sv : '537.36';
      _userAgent = Platform.isAndroid
          ? 'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/$cv Mobile Safari/537.36'
          : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
              'AppleWebKit/$sv (KHTML, like Gecko) '
              'Version/17.0 Mobile/15E148 Safari/$sv';
    }
  }

  String get userAgent => _userAgent ?? 'Mozilla/5.0';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => userAgent);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final appNetClient = AppNetClient();
