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
https://github.com/OWNER/floattube/releases/latest/download/FloatTube.dmg
```

### One-time signing setup

Without notarisation the DMG still builds, but anyone who downloads it hits
Gatekeeper and has to dig through System Settings > Privacy & Security to
open it. Notarising removes that entirely. It needs a paid Apple Developer
account, which we have.

1. **Developer ID Application certificate** — Xcode > Settings > Accounts >
   your team > Manage Certificates > "+" > Developer ID Application.
   (An *Apple Development* certificate is NOT enough; that one is only for
   running on your own machines.) Then export it from Keychain Access as a
   `.p12` with a password.
2. **App Store Connect API key** — App Store Connect > Users and Access >
   Integrations > App Store Connect API > Team Keys. Create a key with the
   *Developer* role, download the `.p8` (**you only get one chance**), and
   note the Key ID and Issuer ID.
3. Run `./tools/setup-signing.sh` and hand it those files. It pushes all six
   secrets to the repo.

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
