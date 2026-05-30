import 'package:flutter/material.dart';

class OfflineScreen extends StatefulWidget {
  final WidgetBuilder retryScreenBuilder;

  const OfflineScreen({super.key, required this.retryScreenBuilder});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with TickerProviderStateMixin {
  bool _isRetrying = false;
  Orientation? _currentOrientation;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (orientation != _currentOrientation) {
      setState(() => _currentOrientation = orientation);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRetry() async {
    if (_isRetrying) return;
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryScreenBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _currentOrientation == Orientation.landscape;

    // Use custom WEBP background — project-specific assets
    final bgAsset = isLandscape
        ? 'assets/additional_assets/no_wifi/16x9_no_wifi_screen.webp'
        : 'assets/additional_assets/no_wifi/9x16_no_wifi_screen.webp';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // WEBP background
          Image.asset(
            bgAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) =>
                Container(color: const Color(0xFF0D1B2A)),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 60 : 36,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 52,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Check your connection and tap Retry',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ScaleTransition(
                      scale: _btnScale,
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _isRetrying
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: _isRetrying
                                ? Colors.amber.withValues(alpha: 0.3)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isRetrying
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isRetrying ? null : _onRetry,
                              child: Center(
                                child: _isRetrying
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.amber),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Connecting...',
                                            style: TextStyle(
                                              color: Colors.amber
                                                  .withValues(alpha: 0.9),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Retry',
                                        style: TextStyle(
                                          color: Color(0xFF1A0A00),
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
