# FloatTube

A one-window YouTube app for macOS that floats above everything else.

Opens straight to youtube.com. Always on top. Shows on every desktop.
Remembers its size and position. Logs in with your normal Google account.

## Build

```
./build.sh
open build/FloatTube.app
```

No Xcode project — just `swiftc` and a hand-rolled `.app` bundle.

## Shortcuts

| Key | Action |
|-----|--------|
| `Cmd-0` | Home (youtube.com) |
| `Cmd-R` | Reload |
| `Cmd-[` | Back |
| `Cmd-J` | Snap to top-right corner |
| `Cmd-T` | Toggle float-on-top |
| `Cmd-I` | Toggle click-through |
| `Cmd-=` / `Cmd--` | Less / more transparent |
| `Cmd-Q` | Quit |

The snap button also sits in the titlebar. Clicking it repeatedly cycles
through three sizes (1003x560, 752x420, 501x280), always parked in the
top-right corner of whichever display the window is currently on.

Click-through makes the window inert so you can work "through" it. To get out
of it, click the Dock icon — that reactivates the app and gets you back to the
menu bar.

"Sign out of everything" in the app menu clears the cookie store.

## Notes

- The Safari user-agent in `Sources/main.swift` is load-bearing. Google blocks
  sign-in from apps it detects as embedded webviews.
- The cookie store is persistent and keyed to the bundle ID, so the ad-hoc
  `codesign` step in `build.sh` matters — an unstable signature can cost you
  the login.
