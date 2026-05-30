import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_theme.dart';
import 'core/alert_service.dart';
import 'core/gate_service.dart';
import 'core/net_client.dart';
import 'core/signal_service.dart';
import 'core/tracking_service.dart';
import 'core/vault_service.dart';
import 'screens/boot_screen.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';
import 'services/audio_service.dart';

late final GameProgress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (_) {}

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await appNetClient.init();

  // Game services
  final storage = await StorageService.create();
  progress = GameProgress(storage);
  await AudioService.init(progress);

  // Gray flow services
  final vault = VaultService();
  await vault.init();

  final signal = SignalService();
  final tracker = TrackingService();
  final gate = GateService(vault);
  final alerts = AlertService(vault);

  runApp(StackoTowerApp(
    vault: vault,
    signal: signal,
    tracker: tracker,
    gate: gate,
    alerts: alerts,
  ));
}

class StackoTowerApp extends StatelessWidget {
  final VaultService vault;
  final SignalService signal;
  final TrackingService tracker;
  final GateService gate;
  final AlertService alerts;

  const StackoTowerApp({
    super.key,
    required this.vault,
    required this.signal,
    required this.tracker,
    required this.gate,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stacko Tower',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.sky,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
      ),
      home: BootScreen(
        vault: vault,
        signal: signal,
        tracker: tracker,
        gate: gate,
        alerts: alerts,
      ),
    );
  }
}
