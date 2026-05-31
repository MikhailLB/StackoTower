import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'core/game_home.dart';
import 'sdk/infra/attribution.dart';
import 'sdk/infra/data_store.dart';
import 'sdk/infra/msg_hub.dart';
import 'sdk/infra/net_probe.dart';
import 'sdk/infra/remote_client.dart';
import 'sdk/pages/launch_page.dart';
import 'game/route_level.dart';
import 'screens/game_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';

class StackoApp extends StatelessWidget {
  final DataStore store;
  final NetProbe probe;
  final Attribution signal;
  final RemoteClient client;
  final MsgHub hub;
  final bool remoteEnabled;

  const StackoApp({
    super.key,
    required this.store,
    required this.probe,
    required this.signal,
    required this.client,
    required this.hub,
    required this.remoteEnabled,
  });

  LaunchPage _buildLaunch() => LaunchPage(
        store: store,
        probe: probe,
        signal: signal,
        client: client,
        hub: hub,
      );

  @override
  Widget build(BuildContext context) {
    final Widget home = remoteEnabled
        ? _buildLaunch()
        : const GameHome();

    return MaterialApp(
      title: 'Stacko Tower',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
      ),
      home: home,
      routes: {
        '/loading':      (_) => const LoadingScreen(),
        '/menu':         (_) => const MainMenuScreen(),
        '/level-select': (_) => const LevelSelectScreen(),
        '/game':         (_) => GameScreen(level: routeLevels.first),
        '/settings':     (_) => const SettingsScreen(),
        '/shop':         (_) => const ShopScreen(),
      },
    );
  }
}
