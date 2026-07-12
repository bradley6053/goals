# Ember — Progress

A native SwiftUI iOS goals-tracking app with a home-screen widget, a Sweetens Cove–themed golf scorecard tab, a "Dad Clock" timers tab with Live Activities, and a candlelit Daily Reflection tab. Personal project.

## Snapshot (2026-07-11)
- **Status:** ✅ Build succeeds (app + widget), ✅ all 80 unit tests pass (GoalMath 11, StreakMath 13, GoalKind 5, GolfMath 16, GolfAPI 3, TimerMath 21, ReflectionMath 11).
- **Platform:** iOS 18+, SwiftUI, dark mode forced app-wide (golf tab paints its own cream light world), portrait only.
- **Bundle IDs:** app `com.bradniemeier.ember`, widget `com.bradniemeier.ember.widget`, tests `com.bradniemeier.ember.tests`.
- **App group (shared storage):** `group.com.bradniemeier.ember`.
- **Team:** NF6A6F9SXY. Code sign style: Automatic.
- **URL scheme:** `ember://`.

## Project layout
Managed by **XcodeGen** — `Ember.xcodeproj` is generated from `project.yml` and is **gitignored**.
Regenerate after editing `project.yml` or adding/removing source files:
```
xcodegen generate
```

| Area | Files |
|------|-------|
| App shell | `App/EmberApp.swift`, `App/Views/RootTabView.swift`, `App/Support/` — `DemoSeed`, `GolfDemoSeed`, `Haptics` |
| Goal views | `App/Views/` — `GoalListView`, `GoalDetailView`, `GoalEditorView`, `LogProgressSheet`, `CelebrationView`, `Components` |
| Golf views | `App/Views/Golf/` — `GolfHomeView`, `CourseSearchSheet`, `ManualCourseEntryView`, `NewRoundSetupView`, `RoundEntryView`, `RoundSummaryView`, `ScorecardShareCard`, `StatsView`, `RecordsView`, `PassportView`, `GolfCelebrationView`, `ConfettiView`, `GolfComponents` |
| Timer views | `App/Views/Timers/` — `TimersHomeView`, `WindingDialView`, `PresetConfigSheet`; `App/Support/` — `TimerStore`, `TimerNotifications`, `TimerActivityController` |
| Reflection | `App/Views/Reflection/ReflectionHomeView`; `App/Support/ReflectionStore`; `Shared/` — `ReflectionModels`, `ReflectionQuotes`, `ReflectionMath`, `ReflectionTheme` |
| Shared (all targets) | `Shared/` — `Models`, `GoalMath`, `Theme`, `AppGroup`, `ImageStore`, `WidgetSnapshot`, `GolfModels`, `GolfMath`, `GolfTheme`, `GolfAPI`, `TimerMath`, `TimerModels`, `TimerActivityAttributes`, `ReflectionModels`, `ReflectionQuotes`, `ReflectionMath`, `ReflectionTheme` |
| Widget | `Widget/EmberWidget.swift`, `Widget/TimerLiveActivity.swift` |
| Tests | `Tests/` — `GoalMathTests` (11), `StreakMathTests` (13), `GoalKindTests` (5), `GolfMathTests` (16), `GolfAPITests` (3), `TimerMathTests` (21), `ReflectionMathTests` (11) |

## Build & test
```
# Build for simulator
xcodebuild -project Ember.xcodeproj -scheme Ember -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build

# Run tests (use a booted sim id from: xcrun simctl list devices available)
xcodebuild -project Ember.xcodeproj -scheme Ember -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=<SIM_ID>' test
```

## What works
- Goal model with increasing/decreasing direction, milestones, progress fractions (`GoalMath`, fully unit-tested).
- **Three goal kinds** (`Goal.goalTypeName` → `GoalKind`): numeric (start → target readings), **count** ("do X 100 times", one-tap "Check in +1", multiple per day), **streak** ("X days in a row", strict midnight reset, one check-in per day, last-7-days dots). Streak milestones/completion key off the monotonic **best** streak so claimed rewards never re-lock (`achievementValue` in Models.swift — don't switch it to currentStreak without revisiting the milestone-stamping logic). Pure date math in `Shared/StreakMath.swift`.
- Shared save path `App/Support/ProgressLogger.swift` — numeric log sheet and habit check-ins both stamp milestones/completion through it.
- Goal list, detail, create/edit editor (kind picker on create only — kind is locked after creation), log-progress sheet, milestone celebration view.
- Home-screen widget reading a shared snapshot via the app group (`WidgetSnapshot` + `ImageStore`).
- Demo data seeding for previews/first run (`-seedDemo`, `-seedGolfDemo` launch args).
- **Golf tab** (Sweetens Cove theme — cream/pine/sky, serif club headers, "Golf is supposed to be fun"):
  - Bottom TabView: dark Goals tab + light Golf tab, each with its own chrome.
  - Course search via **OpenGolfAPI** (free, keyless, `api.opengolfapi.org`) with scorecard pull-in (tees, ratings/slope, per-hole par/handicap/yardage); courses cached in SwiftData so replays work offline; manual course entry fallback.
  - Hole-by-hole round entry: swipe pager, strokes/putts steppers, fairway (hidden on par 3s) + GIR toggles, penalties; live OUT/IN/TOT/vs-par footer; resume in-progress rounds; 9 or 18 holes (front 9 supported on 18-hole courses).
  - Round summary: classic scorecard grid (circled birdies, squared bogeys), stat chips, score distribution, shareable scorecard image (`ImageRenderer` + `ShareLink`).
  - **Fun feature 1 — Personal Bests:** course-record trophy wall (9/18 split), longest birdie streak, full-screen PB celebration with confetti.
  - **Fun feature 2 — Course Passport:** stamp per course played, 5/10/25 milestones, MapKit pin map (no location permission; `CLGeocoder` fallback for missing coordinates).
  - **Fun feature 3 — Live Round Vibes:** confetti + haptics on birdie/eagle commit, hot/cold streak banners.
  - Deep link `ember://golf` and `-golfTab` launch arg jump to the golf tab; `GOLF_OPEN` env var (simulator) jumps to a specific screen for screenshots.
- Golf data: 5 new SwiftData models (`GolfCourse/GolfTee/GolfHole/GolfRound/GolfHoleScore`) added additively to the existing app-group store — goals data verified intact alongside.
- **Timers tab ("Dad Clock")** — dad-life countdowns with a wind-up dial and Live Activities:
  - **Winding dial:** drag around the circle to wind time on like a kitchen timer — 1 revolution = 60 min, 1-min haptic detents, multiple laps stack hours (4 h cap), counter-clockwise unwinds, springs to whole minutes on release. All angle math (incl. the 12-o'clock unwrap and center dead zone) is pure in `Shared/TimerMath.swift` — 21 tests.
  - **No SwiftData:** timers are Codable JSON at `AppGroup.timersURL` (`active-timers.json`). Remaining time always derives from `endDate` — nothing ticks, so force-kill/relaunch loses nothing. `TimerStore.sweep` drops fired timers on launch + every foregrounding.
  - **Presets:** Leave the House 🚗 / Bedtime 🌙 / Clean-Up 🧹 / Screen Time 📺 / Turn Timer 🔁. Chips pre-wind the dial with a spring; Bedtime counts down to a wall-clock time (set once, `Calendar.nextDate`-based) and starts on tap; the turn timer rotates kid names ("Next · ⟨name⟩" one-tap handoff). Long-press a chip → customize sheet (time / minutes / names), overrides persist in the same JSON.
  - **At zero:** local notification with per-preset playful copy, scheduled at start, cancelled/rescheduled on pause/resume (`TimerNotifications`); permission requested contextually on first timer start; `Haptics.unlock()` if it fires while foregrounded.
  - **Live Activity:** `TimerActivityAttributes` (Shared) + `TimerLiveActivity` (Widget bundle) — Lock Screen banner and Dynamic Island (compact/minimal/expanded) driven by `Text(timerInterval:)`/`ProgressView(timerInterval:)`, so the system advances the countdown with zero updates/pushes. `staleDate = endDate` dims it after firing; cancelled timers end `.immediate`, fired ones linger ~4 min at 0:00. Skipped for timers > 8 h (system cap). `NSSupportsLiveActivities` lives in `project.yml` under the **main app's** info properties. Orphan cleanup on launch.
  - Deep link `ember://timers`, `-timersTab` and `-demoTimer` (2-min sample countdown) launch args.
- **Daily Reflection tab ("Reflect")** — one quote a day to sit with, in its own candlelit umber world (deep umber bg, candle-gold accent, serif quote type — distinct from both the dark Ember and cream golf worlds; `ReflectionTheme`):
  - **210-quote library** (`Shared/ReflectionQuotes.all`) balanced 35 each across six labeled themes — Scripture, Saints & Writers, Fatherhood, Marriage, Leadership, Virtue — chosen to fit Brad (dad, founder/co-CEO, husband, Catholic). Authored **interleaved round-robin** so plain modulo day-selection rotates themes day to day. Public-domain-first sourcing; modern figures only as short attributed lines; unverifiable "saint quotes" marked "Attributed to…". A unit test enforces count/balance/uniqueness/interleave, so edit the array in whole rounds of six.
  - **Deterministic quote of the day** (`Shared/ReflectionMath`, pure, 11 tests): civil-days-since-2025-01-01 (via `Calendar`, never 86 400) modulo library count, negative-safe. Same civil date → same quote in any time zone; walks the whole library (~7 months) before repeating. Re-derived from `Date()` on every render, so midnight rolls the page with no timer/observer.
  - **One-tap check-in** with streak + last-7-days dots, reusing `StreakMath` (`didLog`/`currentStreak`/`recentDays`). "I reflected today" → outlined "Reflected today ✓" (tappable to undo). **No SwiftData** — check-ins are Codable JSON at `AppGroup.reflectionURL` (`reflection.json`), same discipline as `TimerStore`; the goals/golf schema is untouched.
  - Deep link `ember://reflect` and `-reflectTab` launch arg jump to the tab.
  - Library/selection logic lives in `Shared/` so a future reflection widget is a small follow-up (deliberately out of v1 scope).

## Open threads / possible next steps
_(No specific in-flight task was recorded when the prior session terminated — the codebase was left in a green state.)_
- [x] Widget timeline refresh strategy — streak snapshots now get a midnight timeline entry (`displayedStreak` re-derives the shown number so a lapsed streak reads 0 without the app opening); other kinds unchanged (app reloads timelines on every save).
- [ ] Local notifications / reminders for **goals** (timers have theirs; goal reminders still open).
- [ ] Timer feel-tuning on a real device (dial drag friction, haptic detents, Dynamic Island) — simulator can't judge touch feel.
- [ ] Optional: confetti celebration when a timer fires in-foreground (deliberately left out of v1 per Brad's scope choice).
- [ ] iCloud or persistence review (where are goals stored today?).
- [ ] Chart/history visualization in `GoalDetailView`.
- [ ] Broader test coverage beyond `GoalMath`.

## Changelog
- **2026-07-11** — Added the Daily Reflection tab ("Reflect"): a candlelit fourth world (`ReflectionTheme` — umber/candle-gold, serif) showing a deterministic quote of the day from a 210-quote library (`ReflectionQuotes`, 35 × 6 labeled themes, interleaved; PD-first sourcing) selected by `ReflectionMath` (pure, timezone-stable, 11 tests). One-tap check-in with streak + 7-day dots via the existing `StreakMath`, persisted as JSON at `AppGroup.reflectionURL` (**no SwiftData change** — schema untouched, zero migration risk). New launch arg `-reflectTab`; deep link `ember://reflect`. 80 tests green; verified in simulator with screenshots (quote card + warm chrome, checked-in state with 1-day streak/filled dot, cold-launch `ember://reflect` routing + persisted check-in across relaunch).
- **2026-07-04 (night)** — Added the Timers tab ("Dad Clock"): winding-dial timer UX (`TimerMath` pure enum, 21 tests), JSON-persisted `TimerStore` (no SwiftData — schema untouched), preset chips incl. clock-anchored Bedtime and a kid turn timer, local notifications at zero with playful copy, and Live Activities (Lock Screen + Dynamic Island, zero-push `timerInterval` views). New launch args `-timersTab`, `-demoTimer`; deep link `ember://timers`. 69 tests green; verified in simulator with screenshots (running dial, Lock Screen Live Activity, foreground sweep).
- **2026-07-04 (evening)** — Added count + streak goal kinds: additive `goalTypeName` on Goal (lightweight migration verified by installing the new build over old-build data), `StreakMath` (13 tests) + `GoalKindTests` (5), `ProgressLogger` extraction, kind picker in editor (create only), one-tap check-in UX, kind-aware list/detail/widget rendering, streak midnight widget entry, demo seeds ("20 workouts", "Meditate daily"). 48 tests green; list/detail/check-in/editor/migration verified in simulator with screenshots.
- **2026-07-04 (later)** — Course search now suggests as you type (350 ms debounce, cancels superseded requests). Added `CourseEditSheet` to fix a cached course's name/city/state (re-geocodes the passport pin) — reachable via press-and-hold on "Your courses" and the pencil on round setup. Round setup now shows the course's city/state. Root cause: OpenGolfAPI has bad location data on some records (e.g. Evansville Country Club, IN listed as "Winterrowd, IL" with wrong coordinates but a correct scorecard/street address).
- **2026-07-04** — Added the golf scorecard tab: TabView root, Sweetens Cove `GolfTheme`, OpenGolfAPI course search + import, hole-by-hole entry with stats (putts/FIR/GIR/penalties), round summary + share card, records, passport with map, celebrations/confetti. 5 new SwiftData models (additive schema change). EmberTests now depends on the Ember target (fixed clean-build test failures). 32 tests green; verified in simulator with screenshots.
- **2026-07-02** — Initialized git repo + this PROGRESS.md. Reconstructed state after a prior session terminated without a save. Confirmed build + tests green.
