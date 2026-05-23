/// Describes a single game level: how many blocks the player must stack,
/// how fast the hook moves, how strict the overlap check is, and how many
/// coins they earn for completing it.
class LevelConfig {
  const LevelConfig({
    required this.levelNumber,
    required this.targetBlocks,
    required this.hookSpeedMultiplier,
    required this.overlapMultiplier,
    required this.coinReward,
  });

  /// 1-based level index.
  final int levelNumber;

  /// Blocks that must be placed to complete the level.
  final int targetBlocks;

  /// Divides the hook half-period — values > 1 make the hook faster.
  final double hookSpeedMultiplier;

  /// Multiplies [StackoConstants.minOverlapToCount] — values > 1 require
  /// more precise placements.
  final double overlapMultiplier;

  /// Coins awarded on level completion (before any bonus boosts).
  final int coinReward;

  String get displayName => 'Level $levelNumber';
}

/// All predefined levels. Level 11+ is treated as endless challenge mode by
/// the game screen when [levelNumber] > [levels].length.
const levels = <LevelConfig>[
  LevelConfig(
    levelNumber: 1,
    targetBlocks: 5,
    hookSpeedMultiplier: 1.0,
    overlapMultiplier: 1.0,
    coinReward: 50,
  ),
  LevelConfig(
    levelNumber: 2,
    targetBlocks: 7,
    hookSpeedMultiplier: 1.1,
    overlapMultiplier: 1.0,
    coinReward: 75,
  ),
  LevelConfig(
    levelNumber: 3,
    targetBlocks: 9,
    hookSpeedMultiplier: 1.2,
    overlapMultiplier: 1.05,
    coinReward: 100,
  ),
  LevelConfig(
    levelNumber: 4,
    targetBlocks: 11,
    hookSpeedMultiplier: 1.3,
    overlapMultiplier: 1.1,
    coinReward: 130,
  ),
  LevelConfig(
    levelNumber: 5,
    targetBlocks: 13,
    hookSpeedMultiplier: 1.4,
    overlapMultiplier: 1.15,
    coinReward: 160,
  ),
  LevelConfig(
    levelNumber: 6,
    targetBlocks: 15,
    hookSpeedMultiplier: 1.5,
    overlapMultiplier: 1.2,
    coinReward: 200,
  ),
  LevelConfig(
    levelNumber: 7,
    targetBlocks: 17,
    hookSpeedMultiplier: 1.6,
    overlapMultiplier: 1.25,
    coinReward: 240,
  ),
  LevelConfig(
    levelNumber: 8,
    targetBlocks: 19,
    hookSpeedMultiplier: 1.7,
    overlapMultiplier: 1.3,
    coinReward: 280,
  ),
  LevelConfig(
    levelNumber: 9,
    targetBlocks: 20,
    hookSpeedMultiplier: 1.8,
    overlapMultiplier: 1.35,
    coinReward: 320,
  ),
  LevelConfig(
    levelNumber: 10,
    targetBlocks: 25,
    hookSpeedMultiplier: 2.0,
    overlapMultiplier: 1.4,
    coinReward: 400,
  ),
];
