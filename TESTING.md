# Manual test checklist

Run `lua tests/run.lua` and `mac-keys doctor` first. Then, on a real machine,
tick each line. Note the app and what happened for anything that fails.

## Chromium (and Firefox if installed)

- [ ] ⌘T new tab, ⌘W closes the tab (not the window), ⌘⇧T reopens it
- [ ] ⌘L focuses the address bar, ⌘R reloads, ⌘⇧R hard-reloads
- [ ] ⌘1 / ⌘9 jump to first / last tab; ⌘⇧] and ⌘⌥→ next tab
- [ ] ⌘[ / ⌘] back / forward
- [ ] ⌘F find, ⌘G next match, ⌘⇧G previous
- [ ] ⌘= ⌘- ⌘0 zoom
- [ ] ⌘Y history, ⌘⇧J downloads, ⌘⌥I developer tools
- [ ] ⌘-click a link opens it in a background tab; ⌘-drag still moves the window
- [ ] In a text field: ⌘←/→ line start/end, ⌥←/→ by word, ⇧ variants select,
      ⌘⌫ deletes to line start, ⌃A/⌃E/⌃K work like a Mac
- [ ] ⌘Q closes every Chromium window (web apps stay open)

## Ghostty

- [ ] ⌘T new tab, ⌘W closes it, ⌘1 / ⌘2 switch tabs, ⌘N new window
- [ ] ⌘D / ⌘⇧D split right / down, ⌘⌥arrows move between splits
- [ ] ⌘K clears the screen (new window after install)
- [ ] ⌘C / ⌘V copy and paste; ⌘A selects all; ⌘F search
- [ ] ⌘←/→ jump to line start/end in the shell, ⌥←/→ by word, ⌘⌫ deletes the line
- [ ] ⌃C, ⌃D, ⌃A, ⌃R still reach the shell untouched
- [ ] ⌘. interrupts a running command

## Nautilus

- [ ] ⌘↑ parent folder, ⌘↓ opens, ⌘⌫ moves to trash, ⌘⇧. shows hidden files
- [ ] ⌘[ / ⌘] back / forward, ⌘⇧G go to location

## VS Code / editor (if installed)

- [ ] ⌘P quick open, ⌘⇧P command palette, ⌘/ comment, ⌘⌥F replace

## System

- [ ] ⌘Tab with ⌘ held: switcher overlay appears, Tab moves selection,
      releasing ⌘ focuses the selected window and hides the overlay
- [ ] Quick ⌘Tab tap toggles between the two most recent windows
- [ ] ⌘H hides a window; ⌘Tab to it brings it back; ⌃⌥M shows hidden windows
- [ ] ⌘\` cycles windows of the same app
- [ ] ⌃↑ / Mission Control key / 4-finger swipe up opens the overview;
      clicking a workspace or window goes there; Esc closes; 4-finger down closes
- [ ] 3-finger swipe moves between workspaces smoothly and stops at the last one
- [ ] ⌃←/→ switch workspace, ⌃1 goes to workspace 1
- [ ] ⌃⇧→ carries the window to the next workspace; ⌘⌥2 sends it to 2; ⌘⌥⇧2 follows it
- [ ] ⌘⇧3 / ⌘⇧4 screenshots, ⌃⌘Q locks, ⌃⌘F fullscreen, ⌃⌘Space emoji
- [ ] ⌘⌥⎋ then click kills a window; Esc cancels
- [ ] ⌘Space still opens the launcher; typing in it is unaffected by ⌃A/⌘← remaps

## Raw input apps

- [ ] In a game or VM (Steam game, qemu, Moonlight, xfreerdp): ⌃A, ⌘T and
      ⌥← reach the app unchanged

## Toggle

- [ ] `mac-keys off` restores stock Omarchy keys; `mac-keys on` brings them back
- [ ] `mac-keys uninstall` then `mac-keys install` leaves no errors
