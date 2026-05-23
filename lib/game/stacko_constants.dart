import 'package:flame/components.dart';

/// All gameplay constants for StackoTower's portrait 9:16 world.
///
/// Coordinates are in Forge2D meters. Y grows downward (Box2D convention),
/// so stacking "up" means decreasing Y.
class StackoConstants {
  /// Logical render size in meters. Camera zoom is set so [worldWidth] fits
  /// exactly horizontally on the device — gives the correct 9:16 fill on any
  /// portrait phone or tablet.
  static const worldWidth = 9.0;
  static const worldHeight = 16.0;

  /// Camera position at game start (world space). Shifted slightly down so
  /// the ground sits near the lower third while the hook fills the top.
  static Vector2 get initialCameraTarget => Vector2(0, 1.0);

  /// Y of the ground collision floor. Below this = failed placement.
  static const groundTopY = 7.5;

  /// Base platform the player stacks on (the starter building).
  static const startBuildingTopY = 5.1;
  static const startBuildingWidth = 3.0;
  static const startBuildingHeight = 2.7;

  /// Block physics dimensions in meters.
  static const blockWidth = 3.6;
  static const blockHeight = 3.0;

  // --- Hook ---------------------------------------------------------------

  /// Peak horizontal amplitude of the hook slide (meters from world centre).
  /// With worldWidth=9 and blockWidth=3.6, amplitude of 2.5 keeps the block
  /// fully on-screen at both extremes.
  static const hookAmplitude = 2.5;

  /// Gap between the hanging block's bottom edge and the tower top.
  static const hookBlockOffsetAboveTop = 1.0;

  /// Hook sprite rendered height in meters.
  static const hookSpriteHeight = 5.0;

  /// Hook centre sits this many meters ABOVE the camera centre so the crane
  /// extends off the top of the screen while only the hook curl is visible.
  static const hookScreenAnchor = 7.5;

  /// Starting half-period (seconds per one-way traverse). Higher = slower.
  static const hookInitialHalfPeriod = 1.7;

  /// Fastest the hook can ever get.
  static const hookMinHalfPeriod = 0.55;

  /// Speed increase applied per successfully placed block.
  static const hookSpeedUpPerBlock = 0.05;

  // --- Physics -----------------------------------------------------------

  static const gravity = 26.0;
  static const settleSpeedThreshold = 0.25;
  static const settleHoldSeconds = 0.45;
  static const settleTimeoutSeconds = 4.0;

  /// Minimum horizontal overlap (meters) required to count a block as placed.
  static const minOverlapToCount = 1.2;

  // --- Camera ------------------------------------------------------------

  static const cameraOffsetBelowCenter = 2.5;
  static const cameraLerp = 4.0;

  // --- Scoring -----------------------------------------------------------

  static const baseRewardPerBlock = 1;
}
