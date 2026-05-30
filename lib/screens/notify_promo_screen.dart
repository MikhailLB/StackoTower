import 'package:flutter/material.dart';
import '../setup/app_config.dart';
import '../core/signal_service.dart';
import '../core/alert_service.dart';
import '../core/vault_service.dart';
import 'portal_screen.dart' deferred as portal;

class NotifyPromoScreen extends StatefulWidget {
  final VaultService vault;
  final AlertService alerts;
  final SignalService signal;
  final String contentUrl;

  const NotifyPromoScreen({
    super.key,
    required this.vault,
    required this.alerts,
    required this.signal,
    required this.contentUrl,
  });

  @override
  State<NotifyPromoScreen> createState() => _NotifyPromoScreenState();
}

class _NotifyPromoScreenState extends State<NotifyPromoScreen> {
  Orientation? _currentOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (orientation != _currentOrientation) {
      setState(() => _currentOrientation = orientation);
    }
  }

  void _onAccept() async {
    final granted = await widget.alerts.requestPermission();
    if (!mounted) return;
    if (!granted) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (!widget.vault.isNotificationOsDenied()) {
        final skipUntil = now + AppConfig.notificationRetryDelaySeconds;
        await widget.vault.setNotificationSkipUntil(skipUntil);
      }
    }
    _goToContent();
  }

  void _onSkip() async {
    final skipUntil = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        AppConfig.notificationRetryDelaySeconds;
    await widget.vault.setNotificationSkipUntil(skipUntil);
    if (!mounted) return;
    _goToContent();
  }

  Future<void> _goToContent() async {
    await portal.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => portal.PortalScreen(
          url: widget.contentUrl,
          vault: widget.vault,
          alerts: widget.alerts,
          signal: widget.signal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = _currentOrientation == Orientation.landscape;

    // Use custom WEBP backgrounds — project-specific assets
    final bgAsset = isLandscape
        ? 'assets/additional_assets/notifications/16x9_notification.webp'
        : 'assets/additional_assets/notifications/9x16_notification.webp';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // WEBP background image
            Image.asset(
              bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) =>
                  Container(color: const Color(0xFF1A1A2E)),
            ),

            // Portrait layout: buttons at bottom center
            if (!isLandscape)
              Positioned(
                left: size.width * 0.08,
                right: size.width * 0.08,
                bottom: size.height * 0.07,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AcceptButton(onTap: _onAccept),
                    const SizedBox(height: 18),
                    _SkipButton(onTap: _onSkip),
                  ],
                ),
              )
            else
              // Landscape layout: compact, centered
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.06,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: size.width * 0.32,
                      child: _AcceptButton(onTap: _onAccept, compact: true),
                    ),
                    const SizedBox(height: 8),
                    _SkipButton(onTap: _onSkip, compact: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcceptButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _AcceptButton({required this.onTap, this.compact = false});
  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) => AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(vertical: widget.compact ? 12 : 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFFE6A800), const Color(0xFFCC8800)]
                    : [const Color(0xFFFFCC00), const Color(0xFFFF9900)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9900)
                      .withValues(alpha: _pressed ? 0.2 : _glowAnim.value),
                  blurRadius: _pressed ? 8 : 14 + _glowAnim.value * 18,
                  spreadRadius: _pressed ? 0 : _glowAnim.value * 4,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Accept',
                style: TextStyle(
                  color: const Color(0xFF1A0A00),
                  fontSize: widget.compact ? 16 : 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _SkipButton({required this.onTap, this.compact = false});
  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
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
      child: AnimatedOpacity(
        opacity: _pressed ? 0.5 : 0.85,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
          child: Center(
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 16 : 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
