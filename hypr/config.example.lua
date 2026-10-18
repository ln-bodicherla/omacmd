-- Personal settings for omacmd. Copy to ~/.config/hypr/omacmd.lua
-- (`omacmd install` does this for you). Every setting is optional.
return {
  -- Physical ⌃A/⌃E/⌃K/⌃F/⌃B/⌃N/⌃P/⌃D/⌃H edit text like on a Mac in GUI apps.
  -- false keeps Linux behaviour for ⌃ (terminals are never affected).
  emacs_ctrl_keys = true,

  -- Show the ⌘Tab switcher overlay (omacmd.switcher shell plugin).
  -- false switches focus directly on each Tab press instead.
  switcher_ui = true,

  -- Trackpad: 3-finger swipe between workspaces, 4-finger up/down for the overview.
  gestures = true,
  -- Finger travel per workspace; lower is more sensitive.
  swipe_distance = 1000,

  -- ⌘-click sends ⌃-click (open link in new tab); ⌘-drag still moves windows.
  cmd_click = true,

  -- Extra apps that must receive keys untouched (games, VMs, remote desktops).
  -- Lua patterns matched against the whole window class (`hyprctl activewindow`).
  raw_input_classes = {
    -- "my%-game",
  },

  -- Extra apps where ⌘W closes the window instead of sending ⌃W.
  close_window_on_cmd_w = {
    -- "org.example.App",
  },

  -- Your own bindings, applied after omacmd. `mk` has helpers:
  --   mk.bind(keys, description, dispatcher_or_command)
  --   mk.map(keys, description, { default = mk.C("K"), terminal = mk.CS("K"), browser = ... })
  --   mk.C / mk.CS / mk.A / mk.S / mk.K / mk.CA build key chords, mk.seq(...) chains them.
  after = function(mk)
    -- mk.bind("CTRL + ALT + E", "Files", "nautilus")
  end,
}
