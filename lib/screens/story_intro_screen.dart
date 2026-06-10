import 'package:flutter/material.dart';

import '../app/skyline.dart';

class _Panel {
  const _Panel(this.image, this.year, this.title, this.text);
  final String image;
  final String year;
  final String title;
  final String text;
}

const _panels = <_Panel>[
  _Panel(
    'assets/story/story1.png',
    '2147',
    'THE DROWNED WORLD',
    'The seas rose and never stopped. The old cities sank beneath the tide. '
        'What remained of humanity gathered on the last rooftops above the water.',
  ),
  _Panel(
    'assets/story/story2.png',
    'THE PLAN',
    'ONE WAY LEFT — UP',
    'They built ARC: a crane-mind tasked with raising a single megatower out of '
        'the ocean and into the clouds. You are ARC. Stack true. Keep it balanced.',
  ),
  _Panel(
    'assets/story/story3.png',
    'THE GOAL',
    'REACH AETHERIA',
    'High in orbit waits Aetheria, the ark that can carry us onward. Build the '
        'tower floor by floor, district by district, and bring humanity home to the stars.',
  ),
];

/// First-launch cinematic that sets up the campaign's purpose.
class StoryIntroScreen extends StatefulWidget {
  const StoryIntroScreen({super.key});

  @override
  State<StoryIntroScreen> createState() => _StoryIntroScreenState();
}

class _StoryIntroScreenState extends State<StoryIntroScreen> {
  final _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _panels.length - 1;
    return Scaffold(
      backgroundColor: Sky.bg0,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: _panels.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _panelView(_panels[i]),
          ),
          // Top skip.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text('SKIP', style: Sky.label(size: 14, color: Sky.muted)),
                ),
              ),
            ),
          ),
          // Bottom controls.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _panels.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? Sky.cyan
                                  : Sky.muted.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        if (last) {
                          Navigator.of(context).maybePop();
                        } else {
                          _pc.nextPage(
                              duration: const Duration(milliseconds: 300),
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
                          boxShadow: Sky.glow(Sky.cyan, blur: 18),
                        ),
                        child: Text(last ? 'BEGIN THE CLIMB' : 'NEXT',
                            style: Sky.label(size: 18, color: Sky.bg0, spacing: 2)),
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

  Widget _panelView(_Panel p) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(p.image, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: Sky.bg1)),
        // Legibility gradient.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Sky.bg0.withValues(alpha: 0.2),
                Sky.bg0.withValues(alpha: 0.55),
                Sky.bg0.withValues(alpha: 0.96),
              ],
              stops: const [0.0, 0.5, 0.88],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.year, style: Sky.body(size: 14, color: Sky.cyan)),
                const SizedBox(height: 6),
                Text(p.title,
                    style: Sky.display(size: 26), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Text(p.text,
                    style: Sky.body(size: 15), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
