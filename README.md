# SideButtons

![Build](https://github.com/numunun/SideButtons/actions/workflows/build.yml/badge.svg)
![License](https://img.shields.io/github/license/numunun/SideButtons)

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-native-black)
![License](https://img.shields.io/badge/license-GPL--2.0-blue)

A menu bar app that makes the M4/M5 side buttons on third-party mice work as
back/forward navigation on macOS, by synthesising the same three-finger swipe
gesture a trackpad emits.

Native Apple Silicon. Builds without Xcode.app — only the Command Line Tools.

## Why this exists

[SensibleSideButtons](https://github.com/archagon/sensible-side-buttons) solved
this problem in 2018 but has been unmaintained since, and its released binary is
Intel-only. Apple ships the last Rosetta 2 release with macOS 27; from macOS 28
Intel-only apps will no longer launch on Apple silicon. This is a rebuild from
the original source, in Swift, targeting arm64.

If you just want something that works today, consider
[SaneSideButtons](https://github.com/thealpa/SaneSideButtons) — an actively
maintained fork, installable via `brew install --cask sanesidebuttons`. This
project exists mostly because I wanted to understand and control the whole
thing.

## Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools (`xcode-select --install`)
- Accessibility permission

## Build

```sh
git clone https://github.com/numunun/SideButtons.git
cd SideButtons

# Check the private gesture API still works on your macOS version.
# Focus a browser window with history during the 3 second countdown.
swift run SwipeTest left

# Run directly (Accessibility permission attaches to your terminal app):
swift run SideButtons

# Build and install a real .app bundle:
./scripts/bundle.sh --identity "SideButtons Dev" --install
open /Applications/SideButtons.app
```

### About code signing

macOS keys Accessibility permission to the **code signature**, not the file
path. An ad-hoc signature (`codesign -s -`) changes hash on every build, so the
grant is invalidated each time you rebuild — which looks exactly like the app
silently breaking.

Create a stable self-signed certificate once, in Keychain Access → Certificate
Assistant → Create a Certificate. Identity type "Self Signed Root", certificate
type "Code Signing". Name it `SideButtons Dev` and pass it via `--identity`.

## Accessibility permission

System Settings → Privacy & Security → Accessibility. Note there are two panes
with similar names; you want the one under Privacy & Security, which lists apps
with toggles, not the top-level Accessibility pane of assistive features.

Or from the app's menu: **Grant Accessibility Access…**

After granting, quit and relaunch the app. macOS does not apply permission
changes to already-running processes.

## Menu

| Item | Effect |
| --- | --- |
| Enabled | Master on/off |
| Trigger on Mouse Down | Fire on press (default) rather than on release |
| Swap Buttons | Reverse which physical button is back vs forward |
| Open at Login | Register via `SMAppService` (bundled app only) |

## How it works

macOS exposes no public API for a "swipe between pages" gesture. The original
project reverse-engineered the private IOKit/HID packet format that the
multitouch driver emits, serialised it by hand, and injected it through
`CGEventCreateFromData`. That code lives in `Sources/CTouchEvents/` and is
carried here essentially unchanged — it is byte-exact against an undocumented
format, and rewriting it would buy nothing while risking everything.

A `CGEventTap` intercepts `otherMouseDown`/`otherMouseUp` for button numbers
3 and 4, swallows them, and posts a swipe instead.

## Project layout
Sources/
CTouchEvents/ C target: the private-API layer
TouchEvents.c vendored + one modification, GPL-2.0, Calf Trail
IOHIDEventData.h vendored, APSL 2.0, Apple
IOHIDEventTypes.h vendored, APSL 2.0, Apple
SSBSwipe.c thin shim, so Swift never touches CoreFoundation here
include/SSBSwipe.h the only header Swift sees
SideButtons/ the menu bar app
SwipeTest/ standalone gesture harness
Resources/Info.plist
scripts/bundle.sh

SwiftPM handles mixed C and Swift through separate targets, so there is no
bridging header. All UI is built in code and the menu bar icon is an SF Symbol,
which is what removes the dependency on `ibtool` and `actool`, and therefore on
Xcode.app.

## Changes from the original

- Rewritten in Swift, AppKit only. No storyboard, no asset catalog.
- Handles `kCGEventTapDisabledByTimeout` and `kCGEventTapDisabledByUserInput`
  by re-enabling the tap. The original did not, which is why it would stop
  responding after heavy system load.
- Settings are cached in memory rather than read from `UserDefaults` inside the
  event tap callback, which runs on the input hot path.
- `tl_uptime()` in `TouchEvents.c` uses `clock_gettime_nsec_np(CLOCK_UPTIME_RAW)`
  instead of Carbon's `UpTime()` + `AbsoluteToNanoseconds()`. Same value, no
  CoreServices dependency. Note that swapping in `mach_absolute_time()` would be
  wrong on Apple silicon, where the timebase is not 1:1.
- "Open at Login" via `SMAppService`, replacing manual instructions.
- Opens the Accessibility pane directly via URL scheme.
- Removed the donation UI, the Amazon affiliate link, and the archagon.net
  links, which belong to the original author.
- The gesture serialisation itself is unchanged.

## Not planned

- **Mac App Store.** The app cannot be sandboxed; it needs `kCGHIDEventTap` plus
  Accessibility. The GPL conflicts with the App Store terms regardless.
- **Rewriting the gesture synthesis.** See above.

## Credits

- **Alexei Baboulevitch** ([archagon](https://github.com/archagon)) — the
  original SensibleSideButtons, and the work of figuring out that this was
  possible at all.
- **Nathan Vander Wilt / Calf Trail Software** — `TouchEvents.c`, the gesture
  serialisation this all rests on.
- **Wowfunhappy** and **Jan Hülsmann** ([thealpa](https://github.com/thealpa)) —
  fixes and a Swift fork I read while building this.

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).

This is a derivative work of SensibleSideButtons, Copyright © 2018 Alexei
Baboulevitch, licensed GPL-2.0-or-later.

`TouchEvents.c` and `TouchEvents.h` are Copyright © 2010 Calf Trail Software,
LLC, also GPL-2.0-or-later. See `Sources/CTouchEvents/LICENSE-CalfTrail`.
Note that this is the copyright that actually covers the gesture synthesis code
— any relicensing question about this project needs Calf Trail's consent, not
just the SensibleSideButtons author's.

`IOHIDEventData.h` and `IOHIDEventTypes.h` are Apple headers under the Apple
Public Source License 2.0.
