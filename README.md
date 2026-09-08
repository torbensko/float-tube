# FloatTube

A one-window YouTube app for macOS that floats above everything else.

Opens straight to youtube.com. Always on top, on every desktop. Remembers its
size and position. You sign in with your normal Google account and it stays
signed in.

Built because Safari's picture-in-picture only works while audio is playing,
which makes it useless for having a video parked in the corner of a screen.

## Install

```
./install.sh
```

Builds the app, puts it in `/Applications`, and launches it. After that it's a
normal app — double-click it, keep it in the Dock, whatever you like. Re-run
`install.sh` to update in place; your login and window position survive.

`./build.sh` alone just builds into `./build` without installing.

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

Tag a commit and GitHub Actions builds a universal (Apple Silicon + Intel)
DMG, notarises it, and publishes a release:

```
git tag v1.0.0 && git push --tags
```

The download URL is stable, so a website link never needs updating:

```
https://github.com/torbensko/floattube/releases/latest/download/FloatTube.dmg
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

Without them the DMG still builds and installs; it just trips Gatekeeper for
anyone who downloads it.

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
/tmp/makeicon /tmp/FloatTube.iconset
iconutil -c icns /tmp/FloatTube.iconset -o Resources/FloatTube.icns
```
