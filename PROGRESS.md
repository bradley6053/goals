# Ember — Progress

A native SwiftUI iOS goals-tracking app with a home-screen widget. Personal project.

## Snapshot (2026-07-02)
- **Status:** ✅ Build succeeds (app + widget), ✅ all 11 unit tests pass.
- **Platform:** iOS 18+, SwiftUI, dark mode only, portrait only.
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
| App shell | `App/EmberApp.swift`, `App/Support/DemoSeed.swift`, `App/Support/Haptics.swift` |
| Views | `App/Views/` — `GoalListView`, `GoalDetailView`, `GoalEditorView`, `LogProgressSheet`, `CelebrationView`, `Components` |
| Shared (app + widget) | `Shared/` — `Models`, `GoalMath`, `Theme`, `AppGroup`, `ImageStore`, `WidgetSnapshot` |
| Widget | `Widget/EmberWidget.swift` |
| Tests | `Tests/GoalMathTests.swift` (11 tests) |

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
- Goal list, detail, create/edit editor, log-progress sheet, milestone celebration view.
- Home-screen widget reading a shared snapshot via the app group (`WidgetSnapshot` + `ImageStore`).
- Demo data seeding for previews/first run.

## Open threads / possible next steps
_(No specific in-flight task was recorded when the prior session terminated — the codebase was left in a green state.)_
- [ ] Widget timeline refresh strategy / reload after logging progress.
- [ ] Local notifications / reminders.
- [ ] iCloud or persistence review (where are goals stored today?).
- [ ] Chart/history visualization in `GoalDetailView`.
- [ ] Broader test coverage beyond `GoalMath`.

## Changelog
- **2026-07-02** — Initialized git repo + this PROGRESS.md. Reconstructed state after a prior session terminated without a save. Confirmed build + tests green.
