# StackoTower — Site Paver

A one-line route puzzle built with pure Flutter (no game engine). Pave one
continuous road that covers every plot of the lot exactly once, from START
to EXIT, routing around obstacle blocks.

## Content

- **Campaign** — 60 hand-tuned lots across 4 districts (Foundation Yard,
  Neon Harbor, Skyline Heights, Crystal Megapolis), each proven solvable by
  the test suite.
- **Daily Blueprint** — a unique procedurally forged puzzle every calendar
  day, with a day-streak bonus.
- **Endless Shift** — infinite procedurally generated lots with escalating
  difficulty and streak tracking.
- **Stars** — up to 3 stars per campaign lot for mistake-free clears, with
  bonus coin payouts.
- **Awards** — 24 achievements with live progress tracking and coin rewards.
- **Statistics** — lifetime crew records and player ranks.
- **Shop** — 6 block skins, 6 road colour themes, and consumable power-ups,
  all purchased with earned coins (no IAP, no ads).
- **Daily login bonus** — escalating coin gift with a 7-day streak cap.

## Tech notes

- Levels are validated by a Hamiltonian-path solver
  (`lib/game/level_forge.dart`, shared with `test/route_level_test.dart`).
- Campaign lots 16–60 were authored with `tool/forge_campaign.dart`, which
  prints verified `RouteLevel.grid` definitions.
- Persistence via `shared_preferences`; audio via `audioplayers`.

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```
