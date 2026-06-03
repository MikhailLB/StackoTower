import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/stacko_assets.dart';

/// Shown when the device has no active internet connection.
///
/// The background image already contains the "NO INTERNET CONNECTION" icon,
/// title and subtitle — Flutter only adds a functional Retry button so the
/// text from the asset and the Flutter layer never overlap.
class NoWifiScreen extends StatefulWidget {
  /// Called after connectivity is restored and the user taps Retry.
  final VoidCallback onRetry;

  const NoWifiScreen({super.key, required this.onRetry});

  @override
  State<NoWifiScreen> createState() => _NoWifiScreenState();
}

class _NoWifiScreenState extends State<NoWifiScreen> {
  bool _checking = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    // Auto-retry when connectivity is restored.
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet && mounted) widget.onRetry();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onTapRetry() async {
    if (_checking) return;
    setState(() => _checking = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final results = await Connectivity().checkConnectivity();
    final hasNet = results.any((r) => r != ConnectivityResult.none);
    if (!mounted) return;
    setState(() => _checking = false);
    if (hasNet) widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // Button dimensions scale up in landscape.
    final btnWidth = isLandscape ? size.width * 0.42 : size.width * 0.72;
    final btnHeight = isLandscape ? 62.0 : 54.0;
    final btnFontSize = isLandscape ? 22.0 : 18.0;

    // How far from the bottom the button sits (as a fraction of screen height).
    // The image has the yellow button drawn at ~88% height in portrait.
    final btnBottomFraction = isLandscape ? 0.08 : 0.09;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background — contains the icon + title + subtitle.
          Image.asset(
            StackoAssets.noWifi,
            fit: BoxFit.cover,
          ),

          // Functional Retry button — overlaid on the drawn button area.
          Positioned(
            bottom: size.height * btnBottomFraction,
            left: (size.width - btnWidth) / 2,
            width: btnWidth,
            height: btnHeight,
            child: _RetryButton(
              onTap: _onTapRetry,
              checking: _checking,
              fontSize: btnFontSize,
              height: btnHeight,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  const _RetryButton({
    required this.onTap,
    required this.checking,
    required this.fontSize,
    required this.height,
  });

  final VoidCallback onTap;
  final bool checking;
  final double fontSize;
  final double height;

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _pressed
                  ? [const Color(0xFFE8A800), const Color(0xFFB36000)]
                  : [const Color(0xFFFFD93D), const Color(0xFFFF8C00)],
            ),
            borderRadius: BorderRadius.circular(widget.height * 0.38),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD93D).withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.checking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Retry',
                  style: AppTextStyles.button(
                    size: widget.fontSize,
                    color: Colors.white,
                  ).copyWith(
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
