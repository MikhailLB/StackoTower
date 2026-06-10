import 'package:flutter/material.dart';

import '../app/skyline.dart';

class _Step {
  const _Step(this.icon, this.title, this.text, this.color);
  final IconData icon;
  final String title;
  final String text;
  final Color color;
}

const _steps = <_Step>[
  _Step(Icons.touch_app_rounded, 'Tap to Drop',
      'The crane swings a module side to side. Tap anywhere to release it onto the tower.',
      Sky.cyan),
  _Step(Icons.layers_rounded, 'Overlap or Lose',
      'Each module must overlap the one below. Overhang is sliced off and the tower narrows — so aim carefully!',
      Sky.violet),
  _Step(Icons.center_focus_strong_rounded, 'Go Perfect',
      'Line a module up dead-centre for a PERFECT: no trimming, a combo, and the tower widens back a little.',
      Sky.lime),
  _Step(Icons.balance_rounded, 'Mind the Balance',
      'Every block shifts the tower\'s centre of mass. Drifting wind and quakes push it further. Keep the lean meter near centre or it topples.',
      Sky.magenta),
  _Step(Icons.widgets_rounded, 'Use the Modules',
      'Wide blocks are stable, counterweights fix a bad lean, fragile pods need precision, bonus blocks pay coins.',
      Sky.amber),
  _Step(Icons.rocket_launch_rounded, 'Climb the Skyline',
      'Clear campaign districts, chase Endless height, finish the Daily Tower, grab bonus rounds and rebuild New Aetheria to the stars.',
      Sky.cyan),
];

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return Scaffold(
      body: SkyBackdrop(
        glowColor: Sky.cyan,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text('SKIP', style: Sky.label(size: 14, color: Sky.muted)),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _stepView(_steps[i]),
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
                        color: i == _page ? Sky.cyan : Sky.muted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () {
                    if (last) {
                      Navigator.of(context).maybePop();
                    } else {
                      _pc.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Sky.cyan,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: Sky.glow(Sky.cyan, blur: 16),
                    ),
                    child: Text(last ? 'START BUILDING' : 'NEXT',
                        style: Sky.label(size: 18, color: Sky.bg0, spacing: 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepView(_Step s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: s.color.withValues(alpha: 0.6), width: 2),
              boxShadow: Sky.glow(s.color, blur: 24),
            ),
            child: Icon(s.icon, color: s.color, size: 52),
          ),
          const SizedBox(height: 28),
          Text(s.title, style: Sky.display(size: 24), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Text(s.text, style: Sky.body(size: 16), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
