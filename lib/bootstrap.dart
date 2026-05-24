import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'core/white_part.dart';
import 'gate/infra/gate_dispatch.dart';
import 'gate/infra/pulse_relay.dart';
import 'gate/infra/reach_probe.dart';
import 'gate/infra/session_vault.dart';
import 'gate/infra/tracking_signal.dart';
import 'gate/pages/splash_gate.dart';
import 'game/level_config.dart';
import 'screens/game_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';

// ════════════════════════════════════════════════════════════
// StackoGateApp — root widget
// ════════════════════════════════════════════════════════════
//
// ⚠️  IMPORTANT: All white-part game routes MUST be registered
// in the routes: map below. If your game uses named routes
// (e.g. Navigator.pushNamed(context, '/menu')), they must exist
// here or the app will crash with:
//   "Could not find route RouteSettings('/menu', null)"
// ════════════════════════════════════════════════════════════
class StackoGateApp extends StatelessWidget {
  final SessionVault vault;
  final ReachProbe probe;
  final TrackingSignal signal;
  final GateDispatch dispatch;
  final PulseRelay pulse;
  final bool gateEnabled;

  const StackoGateApp({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.pulse,
    required this.gateEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final Widget home = gateEnabled
        ? SplashGate(
            vault: vault,
            probe: probe,
            signal: signal,
            dispatch: dispatch,
            pulse: pulse,
          )
        : const WhitePartEntry();

    return MaterialApp(
      title: 'Stacko Tower',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // Black — prevents sky-blue bleed-through when WebView layout
        // hasn't settled yet on cold-start push tap (see gray_flow_guide §2).
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
      ),
      home: home,
      routes: {
        // ── StackoTower white-part named routes ─────────────
        '/loading':      (_) => const LoadingScreen(),
        '/menu':         (_) => const MainMenuScreen(),
        '/level-select': (_) => const LevelSelectScreen(),
        // GameScreen always receives levelConfig from LevelSelectScreen via
        // MaterialPageRoute — this named route fallback uses level 1 defaults.
        // GameScreen always receives levelConfig from LevelSelectScreen via
        // MaterialPageRoute — this named route fallback uses level 1 defaults.
        '/game':         (_) => GameScreen(levelConfig: levels.first),
        '/settings':     (_) => const SettingsScreen(),
        '/shop':         (_) => const ShopScreen(),
      },
    );
  }
}
