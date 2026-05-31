import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/api_keys.dart';
import '../config/remote_config.dart';
import 'app_client.dart';

class Attribution {
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _conversion;
  Map<String, dynamic>? _deepLink;
  Map<String, dynamic>? _reopen;

  final Completer<Map<String, dynamic>> _convDone = Completer();
  final Completer<void> _linkDone = Completer();

  bool _started = false;
  Future<void>? _initFuture;

  bool get started => _started;

  Future<void> warmup() => _initFuture ??= _init();

  Future<void> _init() async {
    if (_started) return;
    final key = RemoteConfig.analyticsId;
    if (key.isEmpty) {
      _started = true;
      if (!_convDone.isCompleted) _convDone.complete({});
      if (!_linkDone.isCompleted) _linkDone.complete();
      return;
    }
    _started = true;
    try {
      if (Platform.isIOS) await _requestAtt();
      final opts = AppsFlyerOptions(
        afDevKey: key,
        appId: RemoteConfig.appRef,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 4,
      );
      _sdk = AppsflyerSdk(opts);
      _sdk!.onInstallConversionData(_onConversion);
      _sdk!.onAppOpenAttribution(_onReopen);
      _sdk!.onDeepLinking(_onDeepLink);
      await _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (_) {
      if (!_convDone.isCompleted) _convDone.complete({});
      if (!_linkDone.isCompleted) _linkDone.complete();
    }
  }

  Future<void> _requestAtt() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (_) {}
  }

  Map<String, dynamic> _flatten(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    final inner = m['payload'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return m;
  }

  void _onConversion(dynamic raw) async {
    final data = _flatten(raw);
    if (data['af_status'] == 'Organic') {
      await Future.delayed(Duration(seconds: RemoteConfig.retrySecs));
      final retry = await _refreshSync();
      _conversion = retry ?? data;
    } else {
      _conversion = data;
    }
    if (!_convDone.isCompleted) _convDone.complete(_conversion);
  }

  void _onReopen(dynamic raw) => _reopen = _flatten(raw);

  void _onDeepLink(DeepLinkResult r) {
    if (r.deepLink != null) _deepLink = r.deepLink!.clickEvent;
    if (!_linkDone.isCompleted) _linkDone.complete();
  }

  Future<Map<String, dynamic>?> _refreshSync() async {
    try {
      final uid = await deviceId();
      if (uid == null) return null;
      final appId = Platform.isIOS ? RemoteConfig.appRef : RemoteConfig.bundleId;
      final url = syncUrl(appId, uid);
      if (url.isEmpty) return null;
      final resp = await appClient.get(
        Uri.parse(url),
        headers: {'authorization': 'Bearer ${RemoteConfig.analyticsId}'},
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) return d;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> awaitConversion({
    Duration timeout = const Duration(seconds: 7),
  }) =>
      _convDone.future.timeout(timeout, onTimeout: () => {});

  Future<void> awaitDeepLink({
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _linkDone.future.timeout(timeout, onTimeout: () {});

  Future<String?> deviceId() async {
    if (_sdk == null) return null;
    try { return await _sdk!.getAppsFlyerUID(); } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> buildPayload({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};
    if (_conversion != null) body.addAll(_conversion!);
    if (_deepLink != null) {
      _deepLink!.forEach((k, v) => body.putIfAbsent(k, () => v));
    }
    if (_reopen != null) {
      _reopen!.forEach((k, v) => body.putIfAbsent(k, () => v));
    }

    final uid = await deviceId();
    if (uid != null && uid.isNotEmpty) {
      body['af_id'] = uid;
    } else {
      body.putIfAbsent('af_id', () => '');
    }

    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.authorized) {
          final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
          if (idfa.isNotEmpty && !idfa.startsWith('00000000-')) {
            body.putIfAbsent('sub_id_10', () => idfa);
          }
        }
      } catch (_) {}
    }

    body['bundle_id'] = RemoteConfig.bundleId;
    body['store_id']  = RemoteConfig.storeRef;
    body['os']        = Platform.isAndroid ? 'Android' : 'iOS';
    body['locale']    = locale;
    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    if (RemoteConfig.cloudId.isNotEmpty) {
      body['firebase_project_id'] = RemoteConfig.cloudId;
    }

    return body;
  }
}
