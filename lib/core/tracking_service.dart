import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import '../setup/app_config.dart';
import '../setup/keys_info.dart';
import 'net_client.dart';

class TrackingService {
  AppsflyerSdk? _sdk;

  Map<String, dynamic>? _attributionData;
  Map<String, dynamic>? _deepLinkData;
  Map<String, dynamic>? _appOpenAttributionData;

  final Completer<Map<String, dynamic>> _attributionCompleter = Completer();
  final Completer<void> _deepLinkCompleter = Completer();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final opts = AppsFlyerOptions(
      afDevKey: AppConfig.analyticsKey,
      appId: AppConfig.analyticsAppId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 10,
    );
    _sdk = AppsflyerSdk(opts);

    _sdk!.onInstallConversionData((data) async {
      try {
        final payload = (data['payload'] ?? data) as Map<String, dynamic>;
        if (payload['af_status'] == 'Organic') {
          await Future.delayed(Duration(seconds: AppConfig.syncRetrySeconds));
          final retryData = await _refreshAttribution();
          _attributionData = retryData ?? payload;
        } else {
          _attributionData = payload;
        }
        if (!_attributionCompleter.isCompleted) {
          _attributionCompleter.complete(_attributionData!);
        }
      } catch (_) {
        if (!_attributionCompleter.isCompleted) {
          _attributionCompleter.complete(<String, dynamic>{});
        }
      }
    });

    _sdk!.onAppOpenAttribution((data) {
      try {
        _appOpenAttributionData = (data['payload'] ?? data) as Map<String, dynamic>;
      } catch (_) {}
    });

    _sdk!.onDeepLinking((result) {
      try {
        if (result.deepLink != null) {
          _deepLinkData = result.deepLink!.clickEvent;
        }
      } catch (_) {}
      if (!_deepLinkCompleter.isCompleted) {
        _deepLinkCompleter.complete();
      }
    });

    await _sdk!.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
  }

  Future<Map<String, dynamic>?> _refreshAttribution() async {
    try {
      final uid = await getAnalyticsUID();
      if (uid == null) return null;
      final appId = Platform.isIOS ? AppConfig.analyticsAppId : AppConfig.bundleId;
      final url = resolveGcdEndpoint(appId, uid);
      if (url.isEmpty) return null;
      final response = await appNetClient
          .get(
            Uri.parse(url),
            headers: {'authorization': 'Bearer ${AppConfig.analyticsKey}'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> waitForAttribution() async {
    return _attributionCompleter.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => <String, dynamic>{},
    );
  }

  Future<String?> getAnalyticsUID() async {
    if (_sdk == null) return null;
    try {
      return await _sdk!.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<void> waitForDeepLink() async {
    await _deepLinkCompleter.future
        .timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  Future<Map<String, dynamic>> buildRequestBody({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};

    body.addAll(_attributionData ?? {});
    _deepLinkData?.forEach((k, v) => body.putIfAbsent(k, () => v));
    _appOpenAttributionData?.forEach((k, v) => body.putIfAbsent(k, () => v));

    final uid = await getAnalyticsUID();
    body['af_id'] = uid ?? '';
    body['bundle_id'] = AppConfig.bundleId;
    body['os'] = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id'] = AppConfig.storeId;
    body['locale'] = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    if (AppConfig.messagingProjectId.isNotEmpty) {
      body['firebase_project_id'] = AppConfig.messagingProjectId;
    }

    if (kDebugMode) {
      debugPrint('[TrackingService] Request body: ${jsonEncode(body)}');
    }

    return body;
  }
}
