import 'tower_engine.dart';

/// A narrative district = one chapter of the rebuild. Holds the shared
/// setting/rules and the story beats for the floors inside it.
class District {
  const District({
    required this.index,
    required this.name,
    required this.skin,
    required this.mods,
    required this.baseSpeed,
    required this.baseWind,
    required this.lore,
    required this.objective,
  });

  final int index;
  final String name;
  final int skin; // suggested TowerSkin index for flavour
  final Set<FloorMod> mods;
  final double baseSpeed;
  final double baseWind;
  final String lore;
  final String objective;
}

const List<District> districts = [
  District(
    index: 0,
    name: 'Old Town',
    skin: 0,
    mods: {},
    baseSpeed: 1.15,
    baseWind: 0.05,
    lore: 'The floodwaters took the streets. We start again — on the rooftops, '
        'reaching up. The first stones of New Aetheria are laid here.',
    objective: 'Lay a stable foundation above the waterline.',
  ),
  District(
    index: 1,
    name: 'Riverside',
    skin: 2,
    mods: {FloorMod.wind},
    baseSpeed: 1.2,
    baseWind: 0.09,
    lore: 'River winds whip between the old piers. Read the gusts, place against '
        'them, and the tower will hold.',
    objective: 'Build through the river winds.',
  ),
  District(
    index: 2,
    name: 'Market Row',
    skin: 1,
    mods: {FloorMod.fast},
    baseSpeed: 1.35,
    baseWind: 0.06,
    lore: 'The old trade district hums back to life. Cranes move fast here — the '
        'crews have quotas to keep.',
    objective: 'Keep pace with the fast cranes.',
  ),
  District(
    index: 3,
    name: 'Iron Docks',
    skin: 4,
    mods: {FloorMod.heavy},
    baseSpeed: 1.25,
    baseWind: 0.06,
    lore: 'Salvaged steel is heavy and unforgiving. One careless load and the '
        'whole span groans.',
    objective: 'Balance the heavy salvage.',
  ),
  District(
    index: 4,
    name: 'Glass Quarter',
    skin: 5,
    mods: {FloorMod.narrow},
    baseSpeed: 1.3,
    baseWind: 0.07,
    lore: 'Slender glass spires, narrow footings. Precision is the only way up.',
    objective: 'Thread the narrow footings.',
  ),
  District(
    index: 5,
    name: 'Neon Heights',
    skin: 0,
    mods: {FloorMod.gusts},
    baseSpeed: 1.35,
    baseWind: 0.08,
    lore: 'Above the smog the air turns electric. Sudden gusts test every joint.',
    objective: 'Survive the sudden gusts.',
  ),
  District(
    index: 6,
    name: 'Sky Gardens',
    skin: 2,
    mods: {FloorMod.fragileRain},
    baseSpeed: 1.3,
    baseWind: 0.07,
    lore: 'They grow food up here now. The grow-pods are fragile — set them down '
        'gently or lose them.',
    objective: 'Handle the fragile grow-pods.',
  ),
  District(
    index: 7,
    name: 'Cloud Deck',
    skin: 5,
    mods: {FloorMod.quake},
    baseSpeed: 1.4,
    baseWind: 0.07,
    lore: 'The deck sways with the jet stream. The tower itself becomes a '
        'pendulum — time your loads with the swing.',
    objective: 'Stack through the sway.',
  ),
  District(
    index: 8,
    name: 'Storm Spire',
    skin: 4,
    mods: {FloorMod.wind, FloorMod.fast},
    baseSpeed: 1.5,
    baseWind: 0.10,
    lore: 'A permanent storm rings the spire. Fast, windy, merciless — only '
        'master builders climb past here.',
    objective: 'Beat the storm.',
  ),
  District(
    index: 9,
    name: 'Orbit Ring',
    skin: 0,
    mods: {FloorMod.narrow, FloorMod.gusts},
    baseSpeed: 1.5,
    baseWind: 0.10,
    lore: 'The first ring of the orbital scaffold. Thin, exposed, and the colony '
        'is finally in sight.',
    objective: 'Raise the orbital scaffold.',
  ),
  District(
    index: 10,
    name: 'Void Gate',
    skin: 5,
    mods: {FloorMod.quake, FloorMod.heavy},
    baseSpeed: 1.55,
    baseWind: 0.09,
    lore: 'Heavy shielding for the void. It quakes as the gate powers up. Hold '
        'it together a little longer.',
    objective: 'Shield the void gate.',
  ),
  District(
    index: 11,
    name: 'The Apex',
    skin: 4,
    mods: {FloorMod.gusts, FloorMod.fast, FloorMod.narrow},
    baseSpeed: 1.6,
    baseWind: 0.11,
    lore: 'The crown of New Aetheria. Everything at once. Finish it, and humanity '
        'climbs to the stars.',
    objective: 'Crown the tower. Reach the stars.',
  ),
];

/// A district boss — a tough, escalating finale fight with a themed hazard.
class BossSpec {
  const BossSpec({
    required this.name,
    required this.tagline,
    required this.mods,
  });
  final String name;
  final String tagline;
  final Set<FloorMod> mods;
}

/// One boss per district (index 0..11). All escalate (phase up over time).
const List<BossSpec> bosses = [
  BossSpec(name: 'The Foreman', tagline: 'Prove you can build.', mods: {FloorMod.pulseSwing, FloorMod.escalate}),
  BossSpec(name: 'The Gale', tagline: 'The river fights back.', mods: {FloorMod.wind, FloorMod.gusts, FloorMod.escalate}),
  BossSpec(name: 'Rush Hour', tagline: 'No time to think.', mods: {FloorMod.fast, FloorMod.pulseSwing, FloorMod.escalate}),
  BossSpec(name: 'The Crusher', tagline: 'Heavy metal, heavy stakes.', mods: {FloorMod.heavy, FloorMod.deadline, FloorMod.escalate}),
  BossSpec(name: 'The Tightrope', tagline: 'No room for error.', mods: {FloorMod.narrow, FloorMod.shrink, FloorMod.escalate}),
  BossSpec(name: 'The Tempest', tagline: 'The sky turns on you.', mods: {FloorMod.gusts, FloorMod.drift, FloorMod.escalate}),
  BossSpec(name: 'The Deep Freeze', tagline: 'Everything slips.', mods: {FloorMod.iceRain, FloorMod.escalate}),
  BossSpec(name: 'The Pendulum', tagline: 'Ride the sway.', mods: {FloorMod.quake, FloorMod.drift, FloorMod.escalate}),
  BossSpec(name: 'The Maelstrom', tagline: 'All the storm at once.', mods: {FloorMod.wind, FloorMod.fast, FloorMod.gusts, FloorMod.escalate}),
  BossSpec(name: 'Threadneedle', tagline: 'Thread the void.', mods: {FloorMod.narrow, FloorMod.gusts, FloorMod.shrink, FloorMod.escalate}),
  BossSpec(name: 'The Singularity', tagline: 'Gravity itself resists.', mods: {FloorMod.quake, FloorMod.heavy, FloorMod.drift, FloorMod.escalate}),
  BossSpec(name: "Aetheria's Lock", tagline: 'The final ascent.', mods: {FloorMod.gusts, FloorMod.fast, FloorMod.narrow, FloorMod.shrink, FloorMod.escalate}),
];

/// A campaign contract.
class CampaignLevel {
  const CampaignLevel({
    required this.number,
    required this.name,
    required this.district,
    required this.goalType,
    required this.goal,
    required this.startSpeed,
    required this.windMax,
    required this.mods,
    required this.coinReward,
    this.tipId,
    this.tip,
    this.boss,
  });

  final int number;
  final String name;
  final District district;
  final GoalType goalType;
  final int goal;
  final double startSpeed;
  final double windMax;
  final Set<FloorMod> mods;
  final int coinReward;

  /// Contextual coach tip, shown the first time this mechanic appears.
  final String? tipId;
  final String? tip;

  /// Non-null on boss floors (chapter ends).
  final BossSpec? boss;
  bool get isBoss => boss != null;

  bool get isChapterStart => (number - 1) % 5 == 0;
  bool get isChapterEnd => number % 5 == 0;

  String goalText() {
    switch (goalType) {
      case GoalType.height:
        return 'Reach $goal floors';
      case GoalType.limited:
        return 'Place all $goal modules';
      case GoalType.perfects:
        return 'Land $goal perfect drops';
      case GoalType.survive:
        return 'Survive ${goal}s';
    }
  }

  TowerEngine build({int? seed, double extraBaseHalf = 0, double speedMul = 1}) =>
      TowerEngine(
        mode: GameMode.campaign,
        goalType: goalType,
        goal: goal,
        seed: seed,
        startSpeed: startSpeed,
        windMax: windMax,
        mods: mods,
        extraBaseHalf: extraBaseHalf,
        speedMul: speedMul,
      );
}

/// The first five floors are a hand-tuned "hook": each one introduces a single
/// new mechanic with a contextual coach tip, so the first ~5 minutes show off
/// the whole toolbox before difficulty ramps.
final List<CampaignLevel> _hook = [
  CampaignLevel(
    number: 1, name: 'Old Town · 1', district: districts[0],
    goalType: GoalType.height, goal: 6, startSpeed: 1.05, windMax: 0.0,
    mods: const {}, coinReward: 50,
    tipId: 'drop',
    tip: 'Tap to drop a block. It must OVERLAP the one below — any overhang is sliced off, so aim!',
  ),
  CampaignLevel(
    number: 2, name: 'Old Town · 2', district: districts[0],
    goalType: GoalType.height, goal: 7, startSpeed: 1.10, windMax: 0.06,
    mods: const {FloorMod.wind}, coinReward: 70,
    tipId: 'wind',
    tip: 'Wind pushes your tower. Watch the LEAN meter and place blocks against the drift.',
  ),
  CampaignLevel(
    number: 3, name: 'Old Town · 3', district: districts[0],
    goalType: GoalType.perfects, goal: 3, startSpeed: 1.10, windMax: 0.03,
    mods: const {}, coinReward: 90,
    tipId: 'perfect',
    tip: 'Drop a block dead-centre for a PERFECT: no trim, a combo, and the tower widens back.',
  ),
  CampaignLevel(
    number: 4, name: 'Old Town · 4', district: districts[0],
    goalType: GoalType.height, goal: 8, startSpeed: 1.12, windMax: 0.04,
    mods: const {FloorMod.deadline}, coinReward: 110,
    tipId: 'deadline',
    tip: 'Beat the clock! Reach the goal before the timer hits zero.',
  ),
  CampaignLevel(
    number: 5, name: 'Old Town · BOSS', district: districts[0],
    goalType: GoalType.height, goal: 12, startSpeed: 1.18, windMax: 0.06,
    mods: const {FloorMod.pulseSwing, FloorMod.escalate}, coinReward: 200,
    boss: bosses[0],
    tipId: 'boss',
    tip: 'BOSS FLOOR! The hazard escalates over time — finish fast before it overwhelms you.',
  ),
];

const List<GoalType> _goalCycle = [
  GoalType.height,
  GoalType.perfects,
  GoalType.survive,
  GoalType.height,
  GoalType.limited,
];

// Per-floor extra twist so every level inside a district feels different.
const List<Set<FloorMod>> _twistCycle = [
  {},
  {FloorMod.deadline},
  {FloorMod.pulseSwing},
  {FloorMod.drift},
  {FloorMod.reverse},
];

/// 60 contracts: hand-tuned hook (1–5) + 55 generated floors across districts.
final List<CampaignLevel> campaign = [
  ..._hook,
  ...List.generate(55, (k) {
    final number = k + 6;
    final i = number - 1; // global 0-based
    final d = districts[i ~/ 5];
    final f = i % 5;

    // Chapter-end floor (f == 4) is a boss fight.
    if (f == 4) {
      final boss = bosses[d.index];
      return CampaignLevel(
        number: number,
        name: '${d.name} · BOSS',
        district: d,
        goalType: GoalType.height,
        goal: 14 + d.index,
        startSpeed: double.parse((d.baseSpeed + 0.12).toStringAsFixed(2)),
        windMax: double.parse((d.baseWind + 0.02).toStringAsFixed(3)),
        mods: {...d.mods, ...boss.mods},
        coinReward: 120 + number * 14,
        boss: boss,
      );
    }

    final goalType = _goalCycle[f];
    final int goal;
    switch (goalType) {
      case GoalType.height:
      case GoalType.limited:
        goal = 8 + d.index + f * 2;
        break;
      case GoalType.perfects:
        goal = 3 + d.index ~/ 2;
        break;
      case GoalType.survive:
        goal = 15 + d.index * 2;
        break;
    }
    return CampaignLevel(
      number: number,
      name: '${d.name} · ${f + 1}',
      district: d,
      goalType: goalType,
      goal: goal,
      startSpeed: double.parse((d.baseSpeed + f * 0.04).toStringAsFixed(2)),
      windMax: double.parse((d.baseWind + f * 0.004).toStringAsFixed(3)),
      mods: {...d.mods, ..._twistCycle[f]},
      coinReward: 40 + number * 10,
    );
  }),
];

CampaignLevel campaignLevel(int number) =>
    campaign.firstWhere((l) => l.number == number, orElse: () => campaign.first);

int get campaignCount => campaign.length;

int dailySeed(DateTime now) => now.year * 10000 + now.month * 100 + now.day;
