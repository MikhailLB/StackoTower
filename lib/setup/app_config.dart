import 'endpoint_info.dart';
import 'keys_info.dart';
import 'links_config.dart';

class AppConfig {
  static const String bundleId = 'com.stackogames.stackotower';
  static const String storeId  = 'com.stackogames.stackotower';
  static const String appName  = 'Stacko Tower';
  static const String analyticsAppId = '';

  static String get apiEndpoint => resolveEndpoint();
  static String get analyticsKey => resolveAnalyticsKey();
  static String get messagingProjectId => resolveMessagingProject();
  static String get privacyPolicyUrl => privacyPolicyPageUrl;
  static String get supportUrl => supportPageUrl;

  static const int notificationRetryDelaySeconds = 259200;
  static const int syncRetrySeconds = 5;
}
