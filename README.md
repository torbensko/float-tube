# FloatTube

A one-window YouTube app for macOS that floats above everything else.

Opens straight to youtube.com. Always on top, on every desktop. Remembers its
size and position. You sign in with your normal Google account and it stays
signed in.

Built because Safari's picture-in-picture only works while audio is playing,
which makes it useless for having a video parked in the corner of a screen.

<img src="Resources/FloatTube.png" alt="FloatTube floating player logo" width="160">

## Install

[Download FloatTube for macOS](https://github.com/torbensko/float-tube/releases/latest/download/FloatTube.dmg).
Open the DMG, drag FloatTube into Applications, then open it from there.
The download supports Apple Silicon and Intel Macs running macOS 13 or later,
and is Developer ID signed and notarised by Apple. To update, quit FloatTube and replace
its copy in Applications; your settings and browser data remain in place.

### Build from source

With Xcode Command Line Tools installed, run `./install.sh` to build, install
and launch a local copy, or `./build.sh` to build into `./build` only.

## Using it

| Key | Action |
|-----|--------|
| `Cmd-J` | Snap to top-right corner |
| `Cmd-T` | Toggle float-on-top |
| `Cmd-I` | Toggle click-through |
| `Cmd-=` / `Cmd--` | Less / more transparent |
| `Cmd-0` | Home (youtube.com) |
| `Cmd-R` | Reload |
| `Cmd-[` | Back |
| `Cmd-Q` | Quit |

The snap button in the titlebar does the same as `Cmd-J`. Clicking it
repeatedly cycles three sizes (1003x560, 752x420, 501x280), parked flush in
the top-right corner of whichever display the window is currently on.

Click-through makes the window inert so you can work through it. Since you
then can't click the window to turn it off, get back via the menu bar icon or
the Dock icon.

Closing the window hides it, it doesn't quit. `Cmd-Q` is the only thing that
actually quits.

## Releasing

Bump `VERSION` and push to `main`. CI builds a universal (Apple Silicon +
Intel) DMG, notarises it, creates the `v<version>` tag and publishes the
release. Same shape as blint-agentic: the version file drives the release,
not a hand-made tag, so the tag can never disagree with the version baked
into the bundle.

Pushing an unchanged `VERSION` is harmless — a Linux gate checks whether that
release already exists and skips the macOS job entirely.

The download URL is stable, so a website link never needs updating:

```
https://github.com/torbensko/float-tube/releases/latest/download/FloatTube.dmg
```

### One-time signing setup

Uses the same five secrets as `blint-agentic` and `brainstorm`, with the same
names and the same values:

| Secret | |
|--------|--|
| `CERTIFICATE_P12` | Developer ID Application cert, base64 of the `.p12` |
| `CERTIFICATE_PASSWORD` | password for that `.p12` |
| `APPLE_ID` | Apple ID email |
| `APPLE_ID_PASSWORD` | app-specific password |
| `APPLE_TEAM_ID` | team identifier |

`./tools/setup-signing.sh` prompts for them and sets all five. GitHub secrets
are write-only, so they can't be copied from another repo automatically —
take them from wherever the originals live.

All five secrets are required for a public release. Missing credentials or failed
notarization stop publication. Local development builds remain ad-hoc signed.

The release includes a DMG, a ZIP, and SHA256 checksums. Both the app and DMG
are notarized and stapled before the draft release is published.

## Notes for future me

- **The Safari user-agent in `Sources/main.swift` is load-bearing.** Google
  blocks sign-in from anything it detects as an embedded webview. Change that
  string and you may not be able to log in.
- **The ad-hoc `codesign` step matters.** The cookie store is persistent and
  keyed to the bundle identifier, so an unstable signature or a changed
  `CFBundleIdentifier` costs you the login.
- Closing must not quit. On a `.utilityWindow` panel the close button is tiny
  and sits exactly where you grab to drag the window into a corner — wiring
  that to "quit the app" made the window vanish with no crash log and no
  obvious cause.
- Local builds are arm64-only for speed; release builds set `UNIVERSAL=1`
  and `lipo` in an Intel slice.
- The `secrets` context is not available in a step's `if:` condition. Testing
  it there fails silently and skips signing, so the workflow lifts secrets
  into job-level `env` and tests that instead.

## Regenerating the icon

`Resources/FloatTube.icns` is committed, so this is only needed if the design
changes:

```
swiftc -O -o /tmp/makeicon tools/make-icon.swift
/tmp/makeicon /tmp/FloatTube.iconset Resources/FloatTube.png
iconutil -c icns /tmp/FloatTube.iconset -o Resources/FloatTube.icns
```
