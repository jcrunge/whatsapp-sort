# WhatsAppSort

A tiny macOS background utility that keeps WhatsApp downloads from cluttering your
`~/Downloads` folder. Whenever WhatsApp Desktop saves a file (`WhatsApp Audio …`,
`WhatsApp Image …`, `WhatsApp Video …`, etc.) into Downloads, WhatsAppSort moves it
into `~/Documents/WhatsApp/_Inbox/` automatically.

## Why it exists

WhatsApp Desktop for macOS has **no setting to change its download folder** — it
always saves to `~/Downloads` via the system save panel. Over time your Downloads
fill up with loose `WhatsApp *` files. This tool watches Downloads and tidies them
into one place, in real time.

## Why a compiled binary instead of a shell script

Reading `~/Downloads` and writing `~/Documents` from a background agent requires
macOS **Full Disk Access (FDA)**. The naive approach is to grant FDA to
`/bin/bash` and run a shell script — but that gives *every* bash invocation full
disk access, including scripts spawned by things like an npm `postinstall`. That's
a real supply-chain risk.

Instead, WhatsAppSort is a ~50-line C program that:

- takes **no arguments**,
- spawns **no shell**,
- interprets **nothing**,
- only moves regular files named `WhatsApp *` from Downloads to the inbox.

You grant Full Disk Access to **this binary alone**. Even if something malicious
executed it, the worst it can do is move your WhatsApp files. `bash` keeps no
special access.

## How it works

```
WhatsApp saves "WhatsApp ..." into ~/Downloads
        │
        ▼
launchd WatchPaths notices ~/Downloads changed
        │
        ▼
runs WhatsAppSort (compiled binary, no shell)
        │
        ▼
moves the file → ~/Documents/WhatsApp/_Inbox/
        │
        ▼
logs it to ~/Documents/WhatsApp/.wa-sort.log
```

Pieces installed:

| Path | Role |
|------|------|
| `~/Applications/WhatsAppSort.app` | the binary (needs Full Disk Access) |
| `~/Library/LaunchAgents/com.github.whatsapp-sort.plist` | watches `~/Downloads`, starts at login |
| `~/Documents/WhatsApp/_Inbox/` | destination |
| `~/Documents/WhatsApp/.wa-sort.log` | move log |

## Install

```bash
git clone https://github.com/jcrunge/whatsapp-sort.git
cd whatsapp-sort
./install.sh
```

Then the one step that cannot be automated (macOS security):

1. Open **System Settings → Privacy & Security → Full Disk Access**
2. Add `~/Applications/WhatsAppSort.app`
3. Turn its switch **ON**

That's it — new WhatsApp downloads land in `~/Documents/WhatsApp/_Inbox/` within a
couple of seconds.

## Uninstall

```bash
./uninstall.sh
```

Your already-sorted files are left untouched. (Optionally remove WhatsAppSort from
the Full Disk Access list afterward.)

## Limitations

- Only catches files that **start with `WhatsApp `** (the names WhatsApp auto-assigns
  to audio/image/video/sticker downloads). Files you save under their own name
  (e.g. `song.wav`) can't be detected — the downloaded file carries no metadata
  about which chat it came from.
- For the same reason it **cannot sort by chat**. Everything lands in `_Inbox`;
  organize into per-chat subfolders yourself.
- macOS only (uses `launchd` + `clang`; builds on both Apple Silicon and Intel).

## License

MIT — see [LICENSE](LICENSE).
