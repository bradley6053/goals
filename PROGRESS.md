# Ember — Progress

A native SwiftUI iOS goals-tracking app with a home-screen widget, plus a Sweetens Cove–themed golf scorecard tab. Personal project.

## Snapshot (2026-07-04)
- **Status:** ✅ Build succeeds (app + widget), ✅ all 48 unit tests pass (GoalMath 11, StreakMath 13, GoalKind 5, GolfMath 16, GolfAPI 3).
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
| Shared (all targets) | `Shared/` — `Models`, `GoalMath`, `Theme`, `AppGroup`, `ImageStore`, `WidgetSnapshot`, `GolfModels`, `GolfMath`, `GolfTheme`, `GolfAPI` |
| Widget | `Widget/EmberWidget.swift` |
| Tests | `Tests/` — `GoalMathTests` (11), `GolfMathTests` (16), `GolfAPITests` (3) |

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

## Open threads / possible next steps
_(No specific in-flight task was recorded when the prior session terminated — the codebase was left in a green state.)_
- [x] Widget timeline refresh strategy — streak snapshots now get a midnight timeline entry (`displayedStreak` re-derives the shown number so a lapsed streak reads 0 without the app opening); other kinds unchanged (app reloads timelines on every save).
- [ ] Local notifications / reminders.
- [ ] iCloud or persistence review (where are goals stored today?).
- [ ] Chart/history visualization in `GoalDetailView`.
- [ ] Broader test coverage beyond `GoalMath`.

## Changelog
- **2026-07-04 (evening)** — Added count + streak goal kinds: additive `goalTypeName` on Goal (lightweight migration verified by installing the new build over old-build data), `StreakMath` (13 tests) + `GoalKindTests` (5), `ProgressLogger` extraction, kind picker in editor (create only), one-tap check-in UX, kind-aware list/detail/widget rendering, streak midnight widget entry, demo seeds ("20 workouts", "Meditate daily"). 48 tests green; list/detail/check-in/editor/migration verified in simulator with screenshots.
- **2026-07-04 (later)** — Course search now suggests as you type (350 ms debounce, cancels superseded requests). Added `CourseEditSheet` to fix a cached course's name/city/state (re-geocodes the passport pin) — reachable via press-and-hold on "Your courses" and the pencil on round setup. Round setup now shows the course's city/state. Root cause: OpenGolfAPI has bad location data on some records (e.g. Evansville Country Club, IN listed as "Winterrowd, IL" with wrong coordinates but a correct scorecard/street address).
- **2026-07-04** — Added the golf scorecard tab: TabView root, Sweetens Cove `GolfTheme`, OpenGolfAPI course search + import, hole-by-hole entry with stats (putts/FIR/GIR/penalties), round summary + share card, records, passport with map, celebrations/confetti. 5 new SwiftData models (additive schema change). EmberTests now depends on the Ember target (fixed clean-build test failures). 32 tests green; verified in simulator with screenshots.
- **2026-07-02** — Initialized git repo + this PROGRESS.md. Reconstructed state after a prior session terminated without a save. Confirmed build + tests green.
