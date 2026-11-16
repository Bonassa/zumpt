# Zumpt

A macOS app that puts your calendar and your to-do list in the same place, so tasks live where you already look all day.
Calendar events are read from the macOS Calendar through EventKit, read-only, so every account already set up there (Google, Exchange, iCloud) shows up with no extra setup.
Tasks live in the app.

Where the project is going and what is left lives in [docs/ROADMAP.md](docs/ROADMAP.md).
Requirements for the upcoming work live in [docs/prds/](docs/prds/README.md).

## Requirements

- macOS 26 or later.
- Xcode 26 or later.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
- An Apple Account added in Xcode > Settings > Accounts, with an "Apple Development" certificate.

## Commands

| Command | What it does |
| --- | --- |
| `make run` | Generates the Xcode project, builds the app and opens it |
| `make build` | Generates the Xcode project and builds the app |
| `make test` | Runs the `ZumptKit` tests with `swift test`, without launching the app (same as `make test-unit`) |
| `make test-ui` | Runs the XCUITest suite against the app, with a fixed date and locale |
| `make test-ui ONLY=DragTasksTests` | Runs only some UI tests: classes or `Class/testName`, separated by commas |
| `make test-all` | Runs the unit tests, then the UI tests |
| `make lint` | Checks formatting and style with `swift format` in strict mode |
| `make format` | Formats the code in place |
| `make generate` | Regenerates `Zumpt.xcodeproj` from `project.yml` |
| `make clean` | Removes build output and the generated project |

The Xcode project is generated and not committed.
Change targets and build settings in `project.yml`, never in Xcode, and run any command above to regenerate it.

UI tests take over the mouse and keyboard while they run, so the full suite is meant for CI.
GitHub Actions runs lint, the unit tests and the UI tests on every pull request and on every push to `main`.
Locally, run `make test`, plus `make test-ui ONLY=...` for the screens you changed.

## Layout

| Path | Contents |
| --- | --- |
| `App/` | The macOS app target: SwiftUI views and app wiring |
| `Packages/ZumptKit/` | Domain types and logic, with no UI, tested with `swift test` |
| `UITests/` | End-to-end tests that drive the app |

UI tests never touch your real Calendar or your real tasks.
They launch the app with options that only exist in Debug builds, so events, tasks, dates and permissions are always the same:

| Option | What it does |
| --- | --- |
| `--calendar-fixture granted\|denied\|notDetermined` | Shows fictional calendars and events instead of the Calendar app, with that access state |
| `--now <ISO 8601 date>` | Starts the clock at that moment, and it keeps ticking from there |
| `--tasks-store memory\|<file>` | Keeps tasks in memory, or in a file inside the app's temporary folder; with `--calendar-fixture` it defaults to `memory` |
| `--task-fixture <names>` | Adds fictional tasks at launch: `backlog`, `week`, `overdue`, or several as `backlog,week` |
| `--appearance light\|dark` | Forces the light or dark appearance, whatever the system uses |

Each run attaches a screenshot of the window to the result bundle in `.build/DerivedData/Logs/Test/`.

## Localization

The source language is English and `App/Localizable.xcstrings` holds the Brazilian Portuguese translation.
The app follows the system language, which can be overridden per app in System Settings > General > Language & Region > Applications.
