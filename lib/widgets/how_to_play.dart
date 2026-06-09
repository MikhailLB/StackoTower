import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'pixel_button.dart';

/// Swipeable tutorial explaining the Site Paver rules. Used as a first-run
/// overlay and from the menu's "How to Play".
class HowToPlayOverlay extends StatefulWidget {
  const HowToPlayOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<HowToPlayOverlay> createState() => _HowToPlayOverlayState();
}

class _HowToPlayOverlayState extends State<HowToPlayOverlay> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = <_Step>[
    _Step(
      icon: Icons.route_rounded,
      title: 'Pave One Road',
      body:
          'Draw a single continuous road that covers every plot on the lot — '
          'exactly once, with no gaps and no crossings.',
    ),
    _Step(
      icon: Icons.play_circle_fill_rounded,
      title: 'Drag From START',
      body:
          'Press the START marker and drag your finger across neighbouring '
          'plots to lay the road block by block.',
    ),
    _Step(
      icon: Icons.undo_rounded,
      title: 'Drag Back to Undo',
      body:
          'Slide back along the road to pull it up, or tap Undo. You can never '
          'pave the same plot twice.',
    ),
    _Step(
      icon: Icons.outlined_flag_rounded,
      title: 'Finish at the EXIT',
      body:
          'Cover the whole lot and end the road right on the EXIT flag to '
          'complete the blueprint. Take your time — no timers.',
    ),
    _Step(
      icon: Icons.star_rounded,
      title: 'Earn Stars',
      body:
          'Clear a lot without Undo or Reset for 3 stars. Up to 3 mistakes '
          'still earns 2. New stars pay bonus coins!',
    ),
    _Step(
      icon: Icons.all_inclusive_rounded,
      title: 'Daily & Endless',
      body:
          'Solve the one-of-a-kind Daily Blueprint to build your streak, or '
          'grind Endless Shifts that grow tougher as you go.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _steps.length - 1) {
      widget.onClose();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Text('Skip',
                      style: AppTextStyles.body(
                          size: 15, color: AppColors.textMuted)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _StepView(step: _steps[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.accent : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
              child: PixelButton(
                label: isLast ? "Start Paving" : 'Next',
                onPressed: _next,
                width: double.infinity,
                height: 56,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Icon(step.icon, color: AppColors.accent, size: 48),
          ),
          const SizedBox(height: 28),
          Text(step.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title(size: 28)),
          const SizedBox(height: 14),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
