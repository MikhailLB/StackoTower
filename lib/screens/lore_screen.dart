import 'package:flutter/material.dart';

import '../app/skyline.dart';
import '../game/campaign.dart';
import '../main.dart';

/// "The Climb" — story codex. Chapters unlock as the player reaches each
/// district, giving the campaign a throughline and a reason to keep building.
class LoreScreen extends StatelessWidget {
  const LoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reached = progress.highestUnlockedLevel; // 1-based level number
    return Scaffold(
      body: SkyBackdrop(
        glowColor: Sky.magenta,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _back(context),
                    const SizedBox(width: 12),
                    Text('THE CLIMB', style: Sky.display(size: 24)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Earth drowned. Humanity builds upward now — one tower to reach '
                  'the orbital colony. You are ARC, the crane that raises New Aetheria.',
                  style: Sky.body(size: 14),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: districts.length,
                  itemBuilder: (_, i) {
                    final d = districts[i];
                    final unlocked = reached > d.index * 5;
                    return _chapterCard(d, unlocked);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chapterCard(District d, bool unlocked) {
    final color = unlocked ? Sky.cyan : Sky.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Sky.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.4),
          boxShadow: unlocked ? Sky.glow(color, blur: 8) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('CH. ${d.index + 1}', style: Sky.body(size: 12, color: color)),
                const SizedBox(width: 8),
                Text(d.name.toUpperCase(), style: Sky.label(size: 17)),
                const Spacer(),
                if (!unlocked) const Icon(Icons.lock_rounded, color: Sky.muted, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              unlocked ? d.lore : 'Reach ${d.name} to unlock this chapter…',
              style: Sky.body(size: 14, color: unlocked ? Sky.text : Sky.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _back(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Sky.panel,
            shape: BoxShape.circle,
            border: Border.all(color: Sky.violet.withValues(alpha: 0.5), width: 1.4),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Sky.text, size: 22),
        ),
      );
}
