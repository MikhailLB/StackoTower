import 'dart:io';
import 'api_keys.dart';
import 'evt_keys.dart';
import 'app_links.dart';

abstract final class RemoteConfig {
  static const String iosStoreId = '6771214956';
  static const String bundleId   = 'com.stackogames.stacko.tower';
  static const String appTitle   = 'Stacko Tower';

  static const int cooldownSecs = 259200;
  static const int retrySecs    = 6;
  static const int bootSecs     = 20;

  static String get endpoint              => remoteUrl();
  static String get analyticsId           => analyticsKey();
  static String get cloudId               => cloudMsgId();
  static String get privacyLinkUrl        => privacyLink;
  static String get supportLinkUrl        => supportLink;
  static String get analyticsIdForPlatform => analyticsId;
  static String get storeRef =>
      Platform.isIOS ? 'id$iosStoreId' : bundleId;
  static String get appRef =>
      Platform.isIOS ? iosStoreId : bundleId;
}
