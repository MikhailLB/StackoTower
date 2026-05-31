import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'gate/infra/gate_dispatch.dart';
import 'gate/infra/pulse_relay.dart';
import 'gate/infra/reach_probe.dart';
import 'gate/infra/session_vault.dart';
import 'gate/infra/tracking_signal.dart';
import 'gate/pages/no_signal_screen.dart';
import 'gate/pages/splash_gate.dart';

// ════════════════════════════════════════════════════════════
// StackoGateApp — root widget (gray-only build)
// ════════════════════════════════════════════════════════════
//
// The white-part game has been removed entirely. The app now only
// ever serves the gray gate (SplashGate → ContentBrowser WebView).
// When the gate is disabled (no credentials provisioned), there is
// nothing to show, so we land on NoSignalScreen with a retry loop.
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

  SplashGate _buildGate() => SplashGate(
        vault: vault,
        probe: probe,
        signal: signal,
        dispatch: dispatch,
        pulse: pulse,
      );

  @override
  Widget build(BuildContext context) {
    final Widget home = gateEnabled
        ? _buildGate()
        : NoSignalScreen(
            probe: probe,
            retryBuilder: (_) => _buildGate(),
          );

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
    );
  }
}
