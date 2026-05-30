import '../helpers/cipher.dart';

String resolveAnalyticsKey() {
  const v = <int>[189, 229, 250, 19, 172, 169, 159, 140, 35, 223, 16, 144, 154, 16, 244, 177, 205, 198, 206, 18, 212, 168];
  return k(v);
}

String resolveMessagingProject() {
  const v = <int>[187, 156, 143, 117, 169, 252, 153, 244, 94, 147, 103];
  return k(v);
}

String resolveGcdEndpoint(String appId, String deviceId) {
  const host = <int>[230, 219, 200, 53, 233, 241, 135, 238, 1, 196, 48, 142, 150, 40, 238, 152, 254, 223, 207, 35, 246, 178, 205, 179, 72, 196, 59, 144];
  const path = <int>[161, 198, 210, 54, 238, 170, 196, 173, 57, 195, 53, 137, 147, 108, 182, 205, 160, 159, 147];
  return '${k(host)}${k(path)}?app_id=$appId&device_id=$deviceId';
}
