import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'app/app_orientation.dart';
import 'app/app_theme.dart';
import 'screens/loading_screen.dart';
import 'screens/no_wifi_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';

late final GameProgress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setOrientationsForLoadingScreens();

  final storage = await StorageService.create();
  progress = GameProgress(storage);

  await AudioService.init(progress);

  runApp(const StackoTowerApp());
}

class StackoTowerApp extends StatelessWidget {
  const StackoTowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackoTower',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.sky,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
      ),
      home: const _ConnectivityGate(),
    );
  }
}

/// Shows [NoWifiScreen] if offline, otherwise goes straight to [LoadingScreen].
class _ConnectivityGate extends StatefulWidget {
  const _ConnectivityGate();

  @override
  State<_ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<_ConnectivityGate> {
  bool _online = true;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _online = online;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      // Brief blank while checking — avoids flicker.
      return const Scaffold(backgroundColor: Colors.black);
    }
    if (!_online) {
      return NoWifiScreen(onRetry: _checkConnectivity);
    }
    return const LoadingScreen();
  }
}
