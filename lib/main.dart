import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_orientation.dart';
import 'bootstrap.dart';
import 'sdk/config/secrets.dart';
import 'sdk/infra/app_client.dart';
import 'sdk/infra/attribution.dart';
import 'sdk/infra/data_store.dart';
import 'sdk/infra/msg_hub.dart';
import 'sdk/infra/net_probe.dart';
import 'sdk/infra/remote_client.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';

late final GameProgress progress;

Future<void> _initCloud() async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setOrientationsForLoadingScreens();
  final storage = await StorageService.create();
  progress = GameProgress(storage);
  await AudioService.init(progress);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final cloudFuture  = _initCloud();
  final agentFuture  = appClient.warmup();
  final store        = DataStore();
  final storeFuture  = store.init().catchError((_) {});

  await cloudFuture;
  await Future.wait([agentFuture, storeFuture]);

  final probe  = NetProbe();
  final signal = Attribution();
  final client = RemoteClient(store);
  final hub    = MsgHub(store);

  unawaited(hub.bootstrap().catchError((_) {}));

  final remoteEnabled =
      remoteUrl().isNotEmpty || analyticsKey().isNotEmpty;

  runApp(StackoApp(
    store: store,
    probe: probe,
    signal: signal,
    client: client,
    hub: hub,
    remoteEnabled: remoteEnabled,
  ));
}
