import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/game_home.dart';
import '../infra/remote_client.dart';
import '../infra/link_bridge.dart';
import '../infra/msg_hub.dart';
import '../infra/net_probe.dart';
import '../infra/data_store.dart';
import '../infra/attribution.dart';
import '../models/wire.dart';
import 'consent_screen.dart';
import 'offline_screen.dart';
import 'web_viewer.dart';

enum _BarStep { empty, midway, done }

class LaunchPage extends StatefulWidget {
  final DataStore store;
  final NetProbe probe;
  final Attribution signal;
  final RemoteClient client;
  final MsgHub hub;

  const LaunchPage({
    super.key,
    required this.store,
    required this.probe,
    required this.signal,
    required this.client,
    required this.hub,
  });

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  VideoPlayerController? _vid;
  bool _vidReady = false;
  _BarStep _bar = _BarStep.empty;
  bool _navigated = false;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _lastOrientation) { _lastOrientation = o; _switchVideo(o); }
  }

  Future<void> _switchVideo(Orientation o) async {
    final asset = o == Orientation.landscape
        ? 'assets/splash/16x9_loading_screen.mp4'
        : 'assets/splash/9x16_loading_screen.mp4';
    final old = _vid;
    final ctrl = VideoPlayerController.asset(asset);
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      ctrl.play();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _vid = ctrl; _vidReady = true; });
      old?.dispose();
    } catch (_) {
      ctrl.dispose();
    }
  }

  void _setBar(_BarStep s) { if (mounted) setState(() => _bar = s); }

  Future<void> _boot() async {
    widget.hub.onTokenRefresh = _onTokenRefresh;

    final nativeColdUrl = await LinkBridge.consumeTapUrl();
    if (nativeColdUrl != null && nativeColdUrl.isNotEmpty) {
      await widget.store.writeMode(AppMode.web);
      await widget.store.consumeOneShotUrl();
      unawaited(_dispatchBackground());
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goContent(nativeColdUrl, coldStartPush: true);
      });
      return;
    }

    _setBar(_BarStep.empty);
    final mode = widget.store.readMode();

    switch (mode) {
      case AppMode.web:
        _setBar(_BarStep.midway);
        final pushFuture = widget.hub.bootstrap().catchError((_) {});
        await _handleWebMode(pushFuture: pushFuture);
        break;
      case AppMode.game:
        _setBar(_BarStep.midway);
        unawaited(widget.hub.bootstrap().catchError((_) {}));
        final recovered = await _tryRecoverWebMode();
        if (recovered) return;
        _setBar(_BarStep.done);
        await Future.delayed(const Duration(milliseconds: 600));
        _goGame();
        break;
      case AppMode.fresh:
        await widget.hub.bootstrap().catchError((_) {});
        await _handleFreshMode();
        break;
    }
  }

  @override
  void dispose() {
    widget.hub.onTokenRefresh = null;
    _vid?.dispose();
    super.dispose();
  }

  Future<void> _dispatchBackground() async {
    try {
      await Future.wait([
        widget.hub.bootstrap().catchError((_) {}),
        widget.signal.warmup().catchError((_) {}),
      ]);
      await Future.wait([
        widget.signal.awaitConversion(timeout: const Duration(seconds: 6)),
        widget.signal.awaitDeepLink(),
      ]);
      final body = await widget.signal.buildPayload(
        locale: Platform.localeName.replaceAll('-', '_'),
        pushToken: widget.hub.token,
      );
      await widget.client.send(body);
    } catch (_) {}
  }

  void _onTokenRefresh(String token) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: token,
    );
    widget.client.send(body);
  }

  Future<void> _handleFreshMode() async {
    _setBar(_BarStep.empty);
    final online = await widget.probe.isOnline();
    if (!online) { if (mounted) _goOffline(fresh: true); return; }

    _setBar(_BarStep.midway);
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.hub.token,
    );
    final reply = await widget.client.send(body);

    if (reply.granted && reply.destination != null) {
      await widget.store.writeMode(AppMode.web);
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goContent(reply.destination!);
    } else {
      await widget.store.writeMode(AppMode.game);
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goGame();
    }
  }

  Future<void> _handleWebMode({Future<void>? pushFuture}) async {
    final netFuture = widget.probe.isOnline();
    if (pushFuture != null) await Future.wait([netFuture, pushFuture]);
    final online = await netFuture;

    if (!online) {
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goOffline(fresh: false);
      return;
    }

    final oneShotUrl = await widget.store.consumeOneShotUrl();
    if (oneShotUrl != null) {
      _setBar(_BarStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goContent(oneShotUrl);
      return;
    }

    final signalFuture = widget.signal.warmup();
    final savedUrl = await widget.store.readSavedUrl();
    await signalFuture;
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 5)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.hub.token,
    );
    final reply = await widget.client.send(body);

    _setBar(_BarStep.done);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (reply.granted && reply.destination != null) {
      _goContent(reply.destination!);
      return;
    }
    if (savedUrl != null) {
      _goContent(savedUrl);
    } else {
      _goOffline(fresh: false);
    }
  }

  Future<bool> _tryRecoverWebMode() async {
    final online = await widget.probe.isOnline();
    if (!online) return false;
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 8)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.hub.token,
    );
    final reply = await widget.client.send(body);
    if (!(reply.granted && reply.destination != null)) return false;
    await widget.store.writeMode(AppMode.web);
    _setBar(_BarStep.done);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return true;
    _goContent(reply.destination!);
    return true;
  }

  void _goContent(String url, {bool coldStartPush = false}) {
    if (_navigated) return;
    _navigated = true;
    if (widget.store.needsPushPrompt()) {
      widget.hub.shouldOfferConsent().then((canAsk) {
        if (!mounted) return;
        if (canAsk) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => ConsentScreen(
              store: widget.store,
              hub: widget.hub,
              probe: widget.probe,
              destination: url,
              coldStartPush: coldStartPush,
              onTokenReady: (token) async {
                final locale = Platform.localeName.replaceAll('-', '_');
                final body = await widget.signal.buildPayload(
                  locale: locale, pushToken: token,
                );
                widget.client.send(body);
              },
            ),
          ));
        } else {
          _directViewer(url, coldStartPush: coldStartPush);
        }
      });
    } else {
      _directViewer(url, coldStartPush: coldStartPush);
    }
  }

  void _directViewer(String url, {bool coldStartPush = false}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WebViewer(
        destination: url,
        store: widget.store,
        hub: widget.hub,
        probe: widget.probe,
        coldStartPush: coldStartPush,
      ),
    ));
  }

  void _goGame() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameHome()),
    );
  }

  void _goOffline({required bool fresh}) {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(
        probe: widget.probe,
        retryBuilder: (_) => LaunchPage(
          store: widget.store,
          probe: widget.probe,
          signal: widget.signal,
          client: widget.client,
          hub: widget.hub,
        ),
      ),
    ));
  }

  String _barAsset() {
    switch (_bar) {
      case _BarStep.empty:  return 'assets/splash/bar_01.webp';
      case _BarStep.midway: return 'assets/splash/bar_02.webp';
      case _BarStep.done:   return 'assets/splash/bar_04.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final barAsset = _barAsset();
    final mq = MediaQuery.of(context);
    final landscape = mq.orientation == Orientation.landscape;
    final barW = landscape
        ? (mq.size.height * 0.35).clamp(0.0, 160.0)
        : (mq.size.width * 0.70).clamp(0.0, 340.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          AnimatedOpacity(
            opacity: _vidReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _vid != null && _vidReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _vid!.value.size.width,
                        height: _vid!.value.size.height,
                        child: VideoPlayer(_vid!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_vidReady)
            Positioned(
              left: 0, right: 0,
              bottom: landscape ? 0 : mq.padding.bottom,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    barAsset,
                    key: ValueKey(barAsset),
                    width: barW,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (ctx, e, st) => const SizedBox(height: 32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
