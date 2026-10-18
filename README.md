# omacmd

> ⌘ on [Omarchy](https://omarchy.org) works like ⌘ on a Mac.

macOS keyboard shortcuts for Omarchy: ⌘, ⌥ and ⌃ do what
they do on a Mac, inside each app, not just in the window manager. Also a
⌘Tab switcher, a Mission Control-style overview and Mac trackpad gestures.

On a Mac keyboard (or Asahi Linux on a MacBook) the ⌘ key is SUPER, so the keys
are already in the right place. On a PC keyboard, see [PC keyboards](#pc-keyboards).

**Status: early (0.1.0).** Developed on one machine (Asahi Linux on a MacBook
Pro, Omarchy 4.0, Hyprland 0.56). The automated tests pass, but the manual
checklist in [TESTING.md](TESTING.md) has not been run end to end yet. Expect
rough edges, and please open an issue with your app and what happened.

## How it works

- **`hypr/translate.lua`** moves Omarchy's window-manager bindings off ⌘ while
  Omarchy's defaults load, so ⌘ is free for apps. New Omarchy defaults are
  moved automatically.
- **`hypr/keys.lua`** binds ⌘/⌥/⌃ shortcuts and rewrites each one for the
  focused app (terminal, Chromium, Firefox, Nautilus, editors, everything
  else), then sends it with Hyprland's `send_key_state`, the same mechanism as
  Omarchy's universal ⌘C/⌘V. Games, VMs and remote desktops get keys untouched.
- **`shell/`** holds two Omarchy shell plugins: the ⌘Tab switcher
  (`omacmd.switcher`) and the overview (`omacmd.overview`).

## Requirements

- Omarchy with Hyprland 0.56 or later (Lua config)
- `jq`, `python3` (installer)
- Ghostty, optionally, for terminal shortcuts like ⌘K

## Install

From the AUR (once published) or a checkout:

```bash
git clone https://github.com/ln-bodicherla/omacmd ~/Projects/omacmd
~/Projects/omacmd/bin/omacmd install
```

`omacmd install` backs up and hooks `~/.config/hypr/hyprland.lua` (rolling back
if Hyprland reports errors), adds a Ghostty `config-file` include, links the shell
plugins and creates `~/.config/hypr/omacmd.lua` for your settings. It is safe to
re-run.

```
omacmd on | off     enable / disable without uninstalling
omacmd status       on/off and Hyprland config errors
omacmd doctor       check the installation
omacmd list         list the shortcuts it binds
omacmd uninstall    remove every hook (keeps your settings file)
```

`omarchy refresh hyprland` replaces `hyprland.lua` and drops the hook; run
`omacmd install` again afterwards (`omacmd doctor` will tell you).

## Shortcuts

### In apps

| Keys | Does |
|---|---|
| ⌘C ⌘V ⌘X ⌘A ⌘Z ⌘⇧Z | copy, paste, cut, select all, undo, redo |
| ⌘T ⌘N ⌘W ⌘⇧T ⌘⇧N | new tab / window, close tab, reopen tab, private window |
| ⌘Q | quit the app (closes all its windows) |
| ⌘L ⌘R ⌘⇧R ⌘F ⌘G ⌘⇧G | address bar, reload, hard reload, find, next / previous match |
| ⌘1–9 | go to tab |
| ⌘[ ⌘] | back / forward |
| ⌘⇧[ ⌘⇧] ⌘⌥← ⌘⌥→ | previous / next tab |
| ⌘= ⌘- ⌘0 | zoom |
| ⌘, ⌘. ⌘/ ⌘⏎ | settings, cancel (Esc), comment, submit |
| ⌘Y ⌘⇧J ⌘⌥B | history, downloads, bookmarks (browsers) |
| ⌘⌥I ⌘⌥J ⌘⌥C ⌘⌥U | developer tools (browsers) |
| ⌘-click | open link in new tab (⌘-drag still moves windows) |

### Text

| Keys | Does |
|---|---|
| ⌘← ⌘→ / ⌘↑ ⌘↓ | line start / end, document top / bottom |
| ⌥← ⌥→ | word left / right |
| add ⇧ | select instead of move |
| ⌘⌫ ⌥⌫ ⌥⌦ | delete to line start, delete word, delete word forward |
| ⌃A ⌃E ⌃K ⌃F ⌃B ⌃N ⌃P ⌃D ⌃H | Mac text-field editing (`emacs_ctrl_keys`) |

### Terminal (Ghostty)

⌘T ⌘N ⌘W ⌘1–9 ⌘⇧[ ⌘⇧] tabs and windows, ⌘D ⌘⇧D splits, ⌘⌥arrows move between
splits, ⌘K clear, ⌘F find, ⌘. interrupt, ⌘←/→ and ⌥←/→ move the cursor the way
your shell expects.

### System

| Keys | Does |
|---|---|
| ⌘Tab ⌘⇧Tab | switch windows (most recent first) |
| ⌘\` | next window of the same app |
| ⌘H ⌘M / ⌃⌥M | hide window / show hidden windows |
| ⌘Space | Omarchy launcher (unchanged) |
| ⌃↑, Mission Control key, 4-finger swipe up | workspace overview |
| ⌃← ⌃→, 3-finger swipe | previous / next workspace |
| ⌃1–0 | go to workspace |
| ⌃⇧← ⌃⇧→ | carry window to previous / next workspace |
| ⌘⌥1–0 / ⌘⌥⇧1–0 | send window to workspace / and follow it |
| ⌘⇧3 ⌘⇧4 ⌘⇧5 | screenshot screen / region / capture menu |
| ⌃⌘F ⌃⌘Q ⌃⌘Space | fullscreen, lock, emoji |
| ⌘⌥⎋ | force quit (click a window) |
| ⌘⌥D | show / hide the bar |

### Where Omarchy's keys moved

| Omarchy | Now |
|---|---|
| ⌘ + window key (T J P O L G S K \` / , ⌫ - = arrows) | ⌃⌥ + same key |
| ⌘1–0 workspaces / ⌘⇧1–0 move window | ⌃1–0 / ⌃⇧1–0 |
| ⌘⇧ + letter app launchers | ⌃⌥⌘ + same letter |
| ⌘⌥⇧ + letter launcher variants | ⌃⌥⌘⇧ + same letter |
| ⌘⏎ terminal | ⌃⌥⌘T |
| ⌘F fullscreen / ⌘⌃F tiled fullscreen / ⌘⌥F full width | ⌃⌘F / ⌃⌥F / ⌃⌥⏎ |
| ⌘⌥1–5 group tabs | ⌃⌥⌘1–5 |
| ⌘⌃⌥ info keys (battery, time, …) | ⌃⌥⇧ + same key |
| ⌘W / ⌘Q close window | Mac ⌘W / ⌘Q |

`omacmd list` and Omarchy's keybindings menu (⌃⌥K) show the live set.

## Settings

`~/.config/hypr/omacmd.lua` (template: [`hypr/config.example.lua`](hypr/config.example.lua)):
turn off the ⌃ text keys, the switcher overlay, gestures or ⌘-click; tune swipe
sensitivity; add apps that need raw keys or where ⌘W closes the window; and add
your own bindings in `after`.

## PC keyboards

The key next to the space bar is Alt on a PC keyboard. To get ⌘ there, swap Alt
and Super in `~/.config/hypr/input.lua`:

```lua
hl.config({ input = { kb_options = "compose:caps,altwin:swap_lalt_lwin" } })
```

## Known limitations

- ⌘Tab switches windows, not apps.
- Letters follow your layout (AZERTY ⌘A is the A key); digits and punctuation
  use key positions, like macOS.
- Apps that ignore ⌃W need adding to `close_window_on_cmd_w`.
- With `emacs_ctrl_keys`, ⌃D in a terminal *inside* an editor (VS Code's panel)
  deletes instead of sending EOF.
- XWayland apps may not receive rewritten shortcuts reliably (a Hyprland limitation).

## Development

```bash
lua tests/run.lua   # translator and keymap tests, Hyprland stubbed
```

Manual checks before a release: [TESTING.md](TESTING.md).

## License

MIT
