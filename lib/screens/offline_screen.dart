import 'package:flutter/material.dart';

class OfflineScreen extends StatefulWidget {
  final WidgetBuilder retryScreenBuilder;

  const OfflineScreen({super.key, required this.retryScreenBuilder});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  bool _isRetrying = false;
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRetry() async {
    if (_isRetrying) return;
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() => _isRetrying = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryScreenBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // The nowifi.png already has the wifi icon, title and subtitle baked in.
    // Flutter only adds a functional Retry button — no duplicate text.
    const bgAsset = 'assets/additional_assets/no_wifi/nowifi.png';

    // Button sizing — larger in landscape so it reads well on wide screens.
    final btnWidth = isLandscape ? size.width * 0.40 : size.width * 0.70;
    final btnHeight = isLandscape ? 62.0 : 56.0;
    final btnFontSize = isLandscape ? 21.0 : 17.0;

    // Vertical position: the image draws the button at ~87 % height in portrait
    // and roughly ~83 % in landscape (image proportions change under cover fit).
    final btnBottom = isLandscape ? size.height * 0.08 : size.height * 0.09;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background — already contains icon + title + subtitle.
          Image.asset(
            bgAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF0D1B2A)),
          ),

          // Functional Retry button — sits over the drawn button in the image.
          Positioned(
            bottom: btnBottom,
            left: (size.width - btnWidth) / 2,
            width: btnWidth,
            height: btnHeight,
            child: ScaleTransition(
              scale: _btnScale,
              child: _RetryButton(
                onTap: _isRetrying ? null : _onRetry,
                isRetrying: _isRetrying,
                fontSize: btnFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.onTap,
    required this.isRetrying,
    required this.fontSize,
  });

  final VoidCallback? onTap;
  final bool isRetrying;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isRetrying
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFFD93D), Color(0xFFFF8C00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        color: isRetrying ? Colors.amber.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isRetrying
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFFFD93D).withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Center(
            child: isRetrying
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.amber.withValues(alpha: 0.9),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Retry',
                    style: TextStyle(
                      color: const Color(0xFF1A0A00),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
