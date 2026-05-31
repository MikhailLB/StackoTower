# StackoTower — App Store Submission Pack
Version: **1.0.2 (build 13)**
Bundle ID: `com.stackotower.app` *(verify in Xcode Signing)*
Category: **Games › Puzzle** (secondary: Family / Brain)
Gameplay genre: **One-line route puzzle (Hamiltonian path)**

---

## 1. App Name (max 30 chars)
```
StackoTower
```

## 2. Subtitle (max 30 chars)
```
One-line road puzzle
```

## 3. Promotional Text (max 170 chars)
```
Draw one continuous road that paves every plot — no crossing, no gaps. 15 hand-crafted lots with obstacle blocks. Pure offline logic. No timers. No ads.
```

## 4. Keywords (max 100 chars)
```
route,puzzle,path,one-line,road,logic,offline,brain,maze,grid,block,problem,pave,planner
```

---

## 5. Full Description

```
StackoTower is a one-line route puzzle: your job is to pave one single, unbroken road that covers every plot on the construction lot — exactly once — starting at the flagged entrance and finishing at the exit.

No physics. No timers. No luck. Just pure spatial thinking.

HOW TO PLAY
• Press and drag from the START marker.
• Route the road through every open plot — you can't cross or revisit.
• Drag back along your road to undo the last steps.
• Reach the EXIT only after covering the entire lot — that's your win.
• Stuck? Hit Undo, Reset, or spend a Skip Pass.

WHAT'S INSIDE
• 15 hand-designed lots, from a gentle 3×3 warm-up to a challenging 9×9 grid.
• Lots 4–15 add obstacle blocks you must route around — no trivial snake solution.
• Every single lot is mathematically proven solvable before shipping.
• A 4-step interactive tutorial teaches the rules in under a minute.
• Earn coins by solving lots, spend them on block skins and power-ups.
• Six unique block skins that tile your finished road.
• A dark "construction site" atmosphere with zero visual clutter.

WHY YOU'LL LIKE IT
• 100% offline — no internet, no account, no login required.
• No ads. No real-money purchases. Every coin is earned by playing.
• No timer — solve at your own pace, put the phone down mid-puzzle.
• Family-friendly. Works equally well for a quick break or a long think session.

One road. Every plot. No shortcuts.
```

---

## 6. What's New (Version 1.0.2)

```
Complete rebuild — brand new gameplay:
• New genre: a one-line route puzzle. Draw one continuous road across every plot.
• 15 original lots, including obstacle blocks to route around.
• Interactive tutorial, drag-to-pave controls, undo/reset, Skip Pass power-up.
• Fresh "construction site" interface rebuilt from scratch.
Thanks for playing!
```

---

## 7. App Review Notes
*(paste into App Store Connect → App Review Information → Notes)*

```
No sign-in required. The app opens directly to the main menu.

In-app purchases: NONE. The in-game shop uses only coins the player earns
by solving puzzles. No real-money transactions of any kind.

Ads: NONE. No advertising SDKs.

Internet: NOT required. The game is 100% offline. The only network use is
two optional links (Privacy Policy / Support) opened in an in-app web view.

Data collection: NONE. All progress is stored locally on-device only.

How to evaluate quickly:
1. Tap "Play" → choose Lot 1 (3×3). A tutorial explains the mechanic.
2. Press and drag from the START dot across every plot to the EXIT flag.
3. Lots 4–15 add obstacle blocks to route around.
4. All 15 lots unlock sequentially on completion.

Re: previous rejection under Guideline 4.3 (Spam) — please see the
Resolution Center cover note below.
```

---

## 8. Resolution Center — Cover Note to the Reviewer

```
Dear App Review Team,

Thank you for your time and for the previous feedback under Guideline 4.3
(Spam). We took the guidance seriously and rebuilt the app entirely rather
than making surface-level adjustments.

WHAT CHANGED

1. Completely new gameplay genre.
   The app is now a one-line route puzzle — sometimes called a Hamiltonian
   path puzzle. The player draws a single unbroken road that visits every
   plot on a construction lot exactly once, starting at a marked entrance
   and ending at a marked exit. This is a spatial-logic and planning
   challenge, not a reaction or timing mechanic, and it is a fundamentally
   different genre from the stacking game previously submitted.

2. Custom-built engine — no game framework.
   We removed the third-party game engine (Flame/forge2d) that was central
   to the previous implementation. The entire puzzle engine and all
   rendering is written from scratch in pure Flutter, giving the app a
   wholly distinct code structure and runtime behaviour.

3. Original, hand-authored content with mathematical verification.
   All 15 puzzle lots are hand-designed. Lots 4–15 include obstacle blocks
   the player must route around, ensuring no trivial "snake" solution
   exists. Every single lot is proven solvable before shipping: we run a
   Hamiltonian-path backtracking solver (with Warnsdorf heuristic + parity
   pre-filter) as an automated test, and the build is rejected if any lot
   fails. This is documented and reproducible.

4. Original interface built from scratch.
   The "neon construction site" visual identity — dot-grid backdrop, neon
   card components, vertical route-map level list — was designed specifically
   for this app and does not share layout or assets with any other title.

5. Different genre from our other puzzle app.
   The studio's other puzzle title (TowerDash Bricks) is a nonogram/picross.
   StackoTower is a one-line route puzzle. These are distinct genres with
   different mechanics, so the two apps do not constitute duplicate content.

THE VALUE WE PROVIDE

• A genuinely challenging spatial-logic puzzle that rewards patient thinking.
  Unlike reaction-based games, difficulty here comes purely from the
  combinatorial complexity of finding a Hamiltonian path on grids with
  obstacles — a well-studied and respected puzzle category.

• A respectful user experience: no sign-in, no account, no ads, no
  real-money purchases, no data collection. Progress is stored locally.
  The player earns every in-game coin by solving puzzles.

• An interactive first-run tutorial makes the mechanic immediately clear
  even to players unfamiliar with path puzzles, broadening accessibility.

We believe this version is a distinct, original, and well-crafted addition
to the Puzzle category and does not resemble generic templates in either
genre, mechanics, code, or visual design.

We welcome any specific questions or requests for additional information
and are happy to make further adjustments based on your guidance.

Sincerely,
The StackoTower team
```

---

## 9. Russian Localisation (ru-RU)

### Subtitle
```
Головоломка одной дорогой
```

### Promotional Text
```
Проведи одну непрерывную дорогу через все участки — без пересечений и пропусков. 15 головоломок с блоками-препятствиями. Чистая логика офлайн, без таймеров и рекламы.
```

### Full Description
```
StackoTower — это головоломка «одной дорогой»: проведи единственную непрерывную дорогу через каждый участок строительного лота, не заезжая дважды, от входа до выхода.

Никакой физики. Никаких таймеров. Никакой удачи. Только пространственное мышление.

КАК ИГРАТЬ
• Нажми и веди от маркера СТАРТ.
• Прокладывай дорогу через каждый открытый участок — пересечения и повторные заезды запрещены.
• Проведи палец обратно вдоль дороги, чтобы отменить шаги.
• На ВЫХОД заезжай только после того, как покрыт весь лот — это победа.
• Застрял? Нажми Отмену, Сброс или потрать Пропуск-пасс.

ЧТО ВНУТРИ
• 15 лотов ручной работы — от лёгкого 3×3 до сложного 9×9.
• Лоты 4–15 содержат блоки-препятствия, вокруг которых нужно прокладывать дорогу.
• Каждый лот математически доказанно решаем до выпуска.
• Интерактивный туториал из 4 шагов — правила за минуту.
• Зарабатывай монеты за решения, трать на скины блоков и бонусы.
• Шесть скинов блоков для оформления готовой дороги.
• Тёмная «стройплощадка» без визуального шума.

ПОЧЕМУ ПОНРАВИТСЯ
• 100% офлайн — интернет, аккаунт и вход не нужны.
• Без рекламы. Без платежей за деньги. Все монеты зарабатываются игрой.
• Без таймера — решай в своём темпе, откладывай в любой момент.
• Подходит для всей семьи: быстрый перерыв или долгое обдумывание.

Одна дорога. Каждый участок. Без срезов.
```

---

## 10. iOS Release Checklist (on macOS)

```
1.  git pull origin white-part-ios
2.  flutter pub get
3.  cd ios && pod install && cd ..
        (Podfile is clean; Flame/forge2d already removed)
4.  open ios/Runner.xcworkspace
5.  Runner target → Signing & Capabilities
        - Set your Team
        - Confirm Bundle Identifier (match App Store Connect record)
6.  Product → Scheme → Release
7.  flutter build ipa --release
        or: Product → Archive in Xcode Organizer
8.  Distribute via Xcode Organizer or Transporter
9.  App Store Connect:
        - Paste sections 1–6 into the listing
        - Paste section 7 into App Review Information → Notes
        - Send section 8 via Resolution Center message
        - App Privacy: Data Not Collected (all local, no tracking)
        - Export Compliance: already set (ITSAppUsesNonExemptEncryption=false in plist)
```
