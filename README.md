# Vimac - Productive macOS keyboard-driven navigation

Vimac is a macOS productivity application that provides keyboard-driven navigation and control of the macOS Graphical User Interface (GUI).

Vimac is heavily inspired by [Vimium](https://github.com/philc/vimium/).

## Getting Started

This fork ships no prebuilt app.
Build it from source (see [Building](#building)), then `make install` to put it in `/Applications`.

Requires macOS 15 or later.

The manual lives in [`docs/manual.md`](docs/manual.md).

## How does Vimac work?

The current Vimac workflow works like this:

1. Activate a mode (`Hold Space to activate Hint-mode` is the default)
2. Perform actions within the activated mode
3. Exit the mode, either manually or automatically when the mode's task is complete

### Hint-mode

Activating Hint-mode allows one to perform a click, double-click, or right-click on an actionable UI element

Upon activation, "hints" will be generated for each actionable element on the frontmost window:

<img src="docs/hint-mode.gif">

Simply type the assigned "hint-text" (eg. "ka") to perform a click at the location!

### Scroll-mode

Activating Scroll-mode allows one to scroll through the scrollable areas of the frontmost window.

Upon activation, a red border surrounds the active scroll area:

<img src="docs/scroll-mode.gif">

HJKL keys can be used to scroll within the scroll area.

## Building

```
open Vimac.xcodeproj
```

Dependencies come from Swift Package Manager, so Xcode resolves them on first
open — `make bootstrap` is only needed for the Ruby gems behind the fastlane
lanes.

`Packages/` holds Vimac's own local Swift packages, for logic that stands apart
from the app: `HintEngine` generates hint labels and matches keystrokes against
them.
Each package carries its own tests, and `make test` runs them alongside the
app's.

Signing settings live in `Config/Project.xcconfig`.
To sign with your own Apple Developer team, set `DEVELOPMENT_TEAM` in a
`Config/Project.local.xcconfig` — it is gitignored and overrides the default.

Add the build to **System Settings > Privacy & Security > Accessibility**.
Dev builds are signed with a team identity, so the grant survives rebuilds.

## Verifying changes from the command line

A `Makefile` wraps the most common verification steps so they don't require
Xcode UI:

```
make build       # Debug build under build/, signed with DEVELOPMENT_TEAM
make test        # Packages/ tests, then the VimacTests unit-test bundle (UI tests skipped — they need Accessibility)
make run         # launch the Debug build (open -n)
make install     # quit any running copy, build Release, install to /Applications, launch
make screenshot  # launch, open Preferences, capture PNG to tmp/screenshots/
```

`make install` builds under the shipping bundle id and refuses to install if
what it built carries a suffix.
Override `INSTALL_DIR` to put it somewhere other than `/Applications`.

Fastlane lanes (`bundle exec fastlane build`, `test`, `screenshot`) wrap the
same scripts for environments that prefer that entry point.

`xcodebuild` output goes through [`xcbeautify`](https://github.com/cpisciotta/xcbeautify)
when it is on `PATH` (`brew install xcbeautify`), and raw otherwise.

The bundle identifier is defined once, in `Config/Project.xcconfig`.
Dev and test builds append a suffix to it (`-dev`, `-test`) so they don't
trigger `AppDelegate.isDuplicateAppInstance()` when an installed copy of Vimac
is also running; set `BUNDLE_ID_SUFFIX=` to build under the shipping id.
Those builds are also named apart — "Vimac Dev", "Vimac Test" — so macOS lists
them distinctly under Privacy & Security.
`make test` uses an isolated `UserDefaults` suite per test, so it will not
disturb the shortcuts of an installed copy.

`make screenshot` needs Screen Recording permission for the terminal running
it; macOS will prompt the first time.
If permission is denied or the Preferences window isn't reachable (e.g.
because the welcome window is up waiting for Accessibility permission), the
script falls back to a full-display capture.

## Contributing

Feel free to contribute to Vimac.
Make sure to open an issue to ask to work on something first!
