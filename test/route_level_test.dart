import 'package:flutter_test/flutter_test.dart';
import 'package:stacko_tower/game/campaign.dart';
import 'package:stacko_tower/game/tower_engine.dart';

void main() {
  test('campaign spans 60 numbered floors across 12 districts', () {
    expect(campaign.length, 60);
    for (var i = 1; i < campaign.length; i++) {
      expect(campaign[i].number, campaign[i - 1].number + 1);
    }
    expect(campaign.first.number, 1);
    expect(campaign.last.number, 60);
  });

  test('a perfectly-centred run never topples and reaches the goal', () {
    final level = campaignLevel(1);
    final engine = level.build(seed: 1);
    var guard = 0;
    while (engine.running && guard++ < 1000) {
      // Always release the block at the crane's centre crossing → balanced.
      // Step the swing until the crane is near centre, then drop.
      var steps = 0;
      while (engine.craneX.abs() > 0.03 && steps++ < 500) {
        engine.update(0.016);
        if (!engine.running) break;
      }
      if (engine.running) engine.drop();
    }
    expect(engine.isWon, isTrue);
    expect(engine.height, greaterThanOrEqualTo(level.goal));
  });

  test('endless engine starts in a running, upright state', () {
    final e = TowerEngine(mode: GameMode.endless, seed: 7);
    expect(e.running, isTrue);
    expect(e.height, 0);
    expect(e.leanPct.abs() < 0.01, isTrue);
  });
}
