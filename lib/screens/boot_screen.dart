import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../app/stacko_assets.dart';
import '../data/session_mode.dart';
import '../core/tracking_service.dart';
import '../core/gate_service.dart';
import '../core/signal_service.dart';
import '../core/alert_service.dart';
import '../core/vault_service.dart';
import '../screens/main_menu_screen.dart';
import 'offline_screen.dart';
import 'notify_promo_screen.dart';
import 'portal_screen.dart' deferred as portal;

enum _BarState { empty, threeQuarter, full }

class BootScreen extends StatefulWidget {
  final VaultService vault;
  final SignalService signal;
  final TrackingService tracker;
  final GateService gate;
  final AlertService alerts;

  const BootScreen({
    super.key,
    required this.vault,
    required this.signal,
    required this.tracker,
    required this.gate,
    required this.alerts,
  });

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  _BarState _bar = _BarState.empty;
  bool _navigated = false;
  Orientation? _currentOrientation;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (orientation != _currentOrientation) {
      _currentOrientation = orientation;
      _switchVideo(orientation);
    }
  }

  Future<void> _switchVideo(Orientation orientation) async {
    final asset = orientation == Orientation.landscape
        ? StackoAssets.splashLandscape
        : StackoAssets.splashPortrait;

    final oldController = _videoController;
    final newController = VideoPlayerController.asset(asset);

    try {
      await newController.initialize();
      newController.setLooping(true);
      newController.setVolume(0);
      newController.play();

      if (!mounted) {
        newController.dispose();
        return;
      }

      setState(() {
        _videoController = newController;
        _videoReady = true;
      });

      oldController?.dispose();
    } catch (_) {
      newController.dispose();
    }
  }

  Future<void> _run() async {
    widget.alerts.onTokenRefresh = _onTokenRefresh;
    await widget.alerts.init().catchError((_) {});

    _setBar(_BarState.empty);

    final mode = widget.vault.getSessionMode();

    switch (mode) {
      case SessionMode.online:
        _setBar(_BarState.threeQuarter);
        await _handleOnlineMode();
        break;
      case SessionMode.offline:
        _setBar(_BarState.threeQuarter);
        await _preloadGameAssets();
        _setBar(_BarState.full);
        await Future.delayed(const Duration(milliseconds: 600));
        _navigateToGame();
        break;
      case SessionMode.pending:
        await _handleFirstLaunch();
        break;
    }
  }

  Future<void> _preloadGameAssets() async {
    // Pre-warm assets so MainMenuScreen feels instant
    try {
      final paths = [
        StackoAssets.startBg,
        StackoAssets.startBuilding,
        StackoAssets.gameName,
        StackoAssets.icon,
      ];
      for (final p in paths) {
        await precacheImage(AssetImage(p), context);
      }
    } catch (_) {}
  }

  Future<void> _handleFirstLaunch() async {
    _setBar(_BarState.empty);

    final hasInternet = await widget.signal.hasInternet();
    if (!hasInternet) {
      if (!mounted) return;
      _navigateToOffline();
      return;
    }

    _setBar(_BarState.threeQuarter);
    await widget.tracker.init();
    await Future.wait([
      widget.tracker.waitForAttribution(),
      widget.tracker.waitForDeepLink(),
    ]);

    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.tracker.buildRequestBody(
      locale: locale,
      pushToken: widget.alerts.token,
    );
    final response = await widget.gate.fetchRemote(body);

    if (response.ok && response.url != null) {
      await widget.vault.setSessionMode(SessionMode.online);
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToContent(response.url!);
    } else {
      await widget.vault.setSessionMode(SessionMode.offline);
      await _preloadGameAssets();
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToGame();
    }
  }

  Future<void> _handleOnlineMode() async {
    final hasInternet = await widget.signal.hasInternet();

    if (!hasInternet) {
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToOffline();
      return;
    }

    final pushUrl = await widget.vault.consumePushUrl();
    if (pushUrl != null) {
      _setBar(_BarState.full);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToContent(pushUrl);
      return;
    }

    final savedUrl = await widget.vault.getSavedUrl();

    await widget.tracker.init();
    await Future.wait([
      widget.tracker
          .waitForAttribution()
          .timeout(const Duration(seconds: 10), onTimeout: () => {}),
      widget.tracker.waitForDeepLink(),
    ]);

    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.tracker.buildRequestBody(
      locale: locale,
      pushToken: widget.alerts.token,
    );
    final response = await widget.gate.fetchRemote(body);

    _setBar(_BarState.full);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (response.ok && response.url != null) {
      _navigateToContent(response.url!);
      return;
    }

    if (savedUrl != null) {
      _navigateToContent(savedUrl);
    } else {
      _navigateToOffline();
    }
  }

  void _onTokenRefresh(String newToken) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.tracker.buildRequestBody(
      locale: locale,
      pushToken: newToken,
    );
    widget.gate.fetchRemote(body);
  }

  void _setBar(_BarState b) {
    if (mounted) setState(() => _bar = b);
  }

  Future<void> _navigateToContent(String url) async {
    if (_navigated) return;
    _navigated = true;

    await portal.loadLibrary();
    await portal.preparePortalEngine();
    if (!mounted) return;

    if (widget.vault.shouldShowNotificationScreen()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NotifyPromoScreen(
            vault: widget.vault,
            alerts: widget.alerts,
            signal: widget.signal,
            contentUrl: url,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => portal.PortalScreen(
            url: url,
            vault: widget.vault,
            alerts: widget.alerts,
            signal: widget.signal,
          ),
        ),
      );
    }
  }

  void _navigateToOffline() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OfflineScreen(
          retryScreenBuilder: (_) => BootScreen(
            vault: widget.vault,
            signal: widget.signal,
            tracker: widget.tracker,
            gate: widget.gate,
            alerts: widget.alerts,
          ),
        ),
      ),
    );
  }

  void _navigateToGame() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  void dispose() {
    widget.alerts.onTokenRefresh = null;
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _currentOrientation == Orientation.landscape;
    final barAsset = switch (_bar) {
      _BarState.empty => StackoAssets.loadingBar(1),
      _BarState.threeQuarter => StackoAssets.loadingBar(3),
      _BarState.full => StackoAssets.loadingBar(4),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          AnimatedOpacity(
            opacity: _videoReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _videoController != null && _videoReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_videoReady)
            Positioned(
              left: 0,
              right: 0,
              bottom: isLandscape
                  ? MediaQuery.of(context).padding.bottom + 15
                  : MediaQuery.of(context).padding.bottom + 20,
              child: Center(
                child: SizedBox(
                  width: isLandscape
                      ? MediaQuery.of(context).size.height * 0.4
                      : MediaQuery.of(context).size.width * 0.7,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Image.asset(
                      barAsset,
                      key: ValueKey(barAsset),
                      fit: BoxFit.fitWidth,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, error, stack) =>
                          const SizedBox(height: 30),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
