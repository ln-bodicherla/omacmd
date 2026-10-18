-- macOS keys, part 2: ⌘ (SUPER), ⌥ (ALT) and ⌃ (CTRL) behave like on a Mac,
-- per app. Each shortcut is rewritten for the focused window and sent to it,
-- the same way Omarchy's universal ⌘C/⌘V already work.
--
-- Contexts: terminal, chromium, firefox (both fall back to "browser"), files
-- (Nautilus), editor (VS Code/Cursor/Zed/JetBrains), raw (games, VMs, remote
-- desktops: keys pass through untouched), default. Terminals only get what
-- their row lists (like Mac Terminal, unknown ⌘ keys do nothing); every other
-- context falls back to "default".
--
-- Called by translate.lua as keys(config, dir); config is the table from
-- ~/.config/hypr/omacmd.lua (see config.example.lua for every option).

return function(cfg, dir)
  cfg = cfg or {}

  local function option(name, default)
    if cfg[name] == nil then return default end
    return cfg[name]
  end

  local EMACS_CTRL_KEYS = option("emacs_ctrl_keys", true)
  local SWITCHER_UI = option("switcher_ui", true)
  local GESTURES = option("gestures", true)
  local CMD_CLICK = option("cmd_click", true)

  -- Lua patterns matched against the whole window class.
  local RAW_INPUT = {
    "steam_app_.*", "gamescope", "com%.libretro%.RetroArch", "com%.moonlight_stream%.Moonlight",
    "GeForceNOW", "[xw]?l?freerdp", "sdl%-freerdp", "qemu", "org%.remmina%.Remmina",
    "looking%-glass%-client", "Minecraft.*", "virt%-manager", "vncviewer", "parsecd",
  }
  for _, p in ipairs(cfg.raw_input_classes or {}) do RAW_INPUT[#RAW_INPUT + 1] = p end

  -- Apps without tabs, where ⌘W should close the window itself.
  local CLOSE_WINDOW_ON_CMD_W = {
    ["mpv"] = true, ["imv"] = true, ["Spotify"] = true, ["spotify"] = true, ["steam"] = true,
    ["org.pulseaudio.pavucontrol"] = true, ["blueberry.py"] = true, ["nm-connection-editor"] = true,
    ["org.gnome.Calculator"] = true, ["org.gnome.Loupe"] = true, ["org.gnome.Evince"] = true,
  }
  for _, c in ipairs(cfg.close_window_on_cmd_w or {}) do CLOSE_WINDOW_ON_CMD_W[c] = true end

  -------------------------------------------------------------------------
  -- Sending keys
  -------------------------------------------------------------------------

  local function press(mods, key, hold)
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = hold or 50, type = "oneshot" })
  end

  local function K(key) return { "", key } end
  local function C(key) return { "CTRL", key } end
  local function CS(key) return { "CTRL SHIFT", key } end
  local function A(key) return { "ALT", key } end
  local function S(key) return { "SHIFT", key } end
  local function CA(key) return { "CTRL ALT", key } end
  local function seq(...) return { ... } end

  local function run(action, window, hold)
    if not action then
      return
    elseif type(action) == "function" then
      action(window)
    elseif type(action[1]) == "table" then
      for i, step in ipairs(action) do
        hl.timer(function() press(step[1], step[2], hold) end, { timeout = 1 + (i - 1) * 70, type = "oneshot" })
      end
    else
      press(action[1], action[2], hold)
    end
  end

  -- Bind strings use keycodes for digits and punctuation; raw passthrough
  -- needs the keysym back.
  local CODE_KEYSYM = {
    [10] = "1", [11] = "2", [12] = "3", [13] = "4", [14] = "5", [15] = "6", [16] = "7", [17] = "8",
    [18] = "9", [19] = "0", [20] = "minus", [21] = "equal", [34] = "bracketleft", [35] = "bracketright",
    [49] = "grave", [59] = "comma", [60] = "period", [61] = "slash",
  }

  -- "SUPER + SHIFT + code:34" -> { "SUPER SHIFT", "bracketleft" }
  local function passthrough_of(keys)
    local mods, key = {}, nil
    for raw in keys:gmatch("[^+]+") do
      local part = raw:match("^%s*(.-)%s*$")
      local up = part:upper()
      if up == "SUPER" or up == "CTRL" or up == "ALT" or up == "SHIFT" then
        mods[#mods + 1] = up
      else
        key = part
      end
    end
    local code = key and tonumber(key:match("^code:(%d+)$"))
    if code then key = CODE_KEYSYM[code] end
    if not key then return nil end
    return { table.concat(mods, " "), key }
  end

  -------------------------------------------------------------------------
  -- Which app is focused
  -------------------------------------------------------------------------

  local function has_tag(window, wanted)
    local tags = window.tags or {}
    if type(tags) == "string" then
      local list = {}
      for t in tags:gmatch("[^,%s]+") do list[#list + 1] = t end
      tags = list
    end
    for _, t in ipairs(tags) do
      if (t:gsub("%*$", "")) == wanted then
        return true
      end
    end
    return false
  end

  local function is_raw(class)
    for _, p in ipairs(RAW_INPUT) do
      if class:match("^" .. p .. "$") then return true end
    end
    return false
  end

  -- A launcher or menu that grabs the keyboard (Omarchy menus, launchers)
  -- should get plain text-field behaviour, not the window underneath.
  local function exclusive_layer_focused()
    for _, layer in ipairs(hl.get_layers() or {}) do
      if layer.mapped and layer.interactivity == 1 then
        return true
      end
    end
    return false
  end

  local function context()
    if exclusive_layer_focused() then
      return "default", nil
    end
    local w = hl.get_active_window()
    if not w then
      return "default", nil
    end
    local class = w.class or ""
    if is_raw(class) then return "raw", w end
    if has_tag(w, "terminal") then return "terminal", w end
    if has_tag(w, "chromium-based-browser") then return "chromium", w end
    if has_tag(w, "firefox-based-browser") then return "firefox", w end
    if class == "org.gnome.Nautilus" then return "files", w end
    if class:match("^[Cc]ode") or class:match("^[Cc]ursor") or class == "dev.zed.Zed"
      or class:match("^jetbrains%-") then
      return "editor", w
    end
    return "default", w
  end

  local function resolve(spec, ctx)
    if spec[ctx] ~= nil then return spec[ctx] end
    if ctx == "terminal" then return nil end
    if (ctx == "chromium" or ctx == "firefox") and spec.browser ~= nil then return spec.browser end
    return spec.default
  end

  local function map(keys, description, spec, opts)
    opts = opts or {}
    if spec.raw == nil then spec.raw = passthrough_of(keys) or false end
    pcall(hl.unbind, keys)
    hl.bind(keys, function()
      local ctx, w = context()
      run(resolve(spec, ctx), w, opts.repeating and 25 or nil)
    end, { description = description, repeating = opts.repeating or false })
  end

  local function exec(cmd)
    return function() hl.exec_cmd(cmd) end
  end

  -------------------------------------------------------------------------
  -- Window actions with Mac semantics
  -------------------------------------------------------------------------

  local function close_window()
    hl.dispatch(hl.dsp.window.close())
  end

  -- ⌘Q quits the app: every window of the focused app's class.
  local function quit_app(w)
    if not w then return end
    for _, x in ipairs(hl.get_windows() or {}) do
      if x.class == w.class then
        hl.dispatch(hl.dsp.window.close({ window = "address:" .. x.address }))
      end
    end
  end

  local function close_tab_or_window(w)
    if w and CLOSE_WINDOW_ON_CMD_W[w.class or ""] then
      close_window()
    else
      press("CTRL", "W")
    end
  end

  -- ⌘H / ⌘M: tuck the window away; ⌘Tab brings it back, ⌃⌥M shows them all.
  local function minimize()
    hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
  end

  local function focus_address(address)
    hl.dispatch(hl.dsp.focus({ window = "address:" .. address }))
    hl.dispatch(hl.dsp.window.bring_to_top())
  end

  -- ⌘` cycles windows of the same app.
  local function same_app_window(step)
    return function(w)
      if not w then return end
      local list = {}
      for _, x in ipairs(hl.get_windows() or {}) do
        if x.class == w.class then list[#list + 1] = x.address end
      end
      if #list < 2 then return end
      table.sort(list)
      for i, a in ipairs(list) do
        if a == w.address then
          focus_address(list[((i - 1 + step) % #list) + 1])
          return
        end
      end
    end
  end

  -------------------------------------------------------------------------
  -- ⌘Tab: most-recently-used window switcher (hold ⌘, tap Tab, let go)
  -------------------------------------------------------------------------

  _G.__omacmd_mru = _G.__omacmd_mru or {}
  local mru = _G.__omacmd_mru
  -- Shared across reloads so a reload mid-cycle can't strand the switcher.
  _G.__omacmd_cycle = nil

  local function touch(address)
    for i = #mru, 1, -1 do
      if mru[i] == address then table.remove(mru, i) end
    end
    table.insert(mru, 1, address)
    while #mru > 64 do table.remove(mru) end
  end

  if _G.__omacmd_active_sub then
    pcall(function() _G.__omacmd_active_sub:remove() end)
  end
  _G.__omacmd_active_sub = hl.on("window.active", function(w)
    if _G.__omacmd_cycle then return end
    if type(w) ~= "table" or not w.address then w = hl.get_active_window() end
    if w and w.address then touch(w.address) end
  end)

  local function super_down()
    for _, k in ipairs({ "Super_L", "Super_R" }) do
      local ok, down = pcall(hl.is_key_down, k)
      if ok and down then return true end
    end
    return false
  end

  local function switcher_ui(cycle)
    if not SWITCHER_UI then return end
    if cycle then
      hl.exec_cmd("omarchy-shell omacmdSwitcher show '" .. table.concat(cycle.list, ",") .. "' " .. (cycle.idx - 1))
    else
      hl.exec_cmd("omarchy-shell omacmdSwitcher hide")
    end
  end

  local function commit_cycle()
    local cycle = _G.__omacmd_cycle
    if not cycle then return end
    _G.__omacmd_cycle = nil
    switcher_ui(nil)
    local address = cycle.list[cycle.idx]
    touch(address)
    local w = hl.get_window("address:" .. address)
    local ws = w and w.workspace
    if ws and type(ws.name) == "string" and ws.name:match("^special:minimized") then
      local active = hl.get_active_workspace()
      if active then
        hl.dispatch(hl.dsp.window.move({ workspace = tostring(active.id), window = "address:" .. address }))
      end
    end
    focus_address(address)
  end

  -- Fallback for a missed ⌘ release: poll the key until it is up.
  local function watch_release(gen)
    hl.timer(function()
      local cycle = _G.__omacmd_cycle
      if not cycle or cycle.gen ~= gen then return end
      if super_down() then
        watch_release(gen)
      else
        commit_cycle()
      end
    end, { timeout = 150, type = "oneshot" })
  end

  local function app_switch(step)
    return function()
      local cycle = _G.__omacmd_cycle
      if not cycle then
        local exists = {}
        for _, x in ipairs(hl.get_windows() or {}) do
          if x.mapped ~= false then exists[x.address] = true end
        end
        local list, seen = {}, {}
        local active = hl.get_active_window()
        if active and exists[active.address] then
          list[1] = active.address
          seen[active.address] = true
        end
        for _, a in ipairs(mru) do
          if exists[a] and not seen[a] then list[#list + 1] = a; seen[a] = true end
        end
        for a in pairs(exists) do
          if not seen[a] then list[#list + 1] = a end
        end
        if #list < 2 then return end
        _G.__omacmd_gen = (_G.__omacmd_gen or 0) + 1
        cycle = { list = list, idx = 1, gen = _G.__omacmd_gen }
        _G.__omacmd_cycle = cycle
        watch_release(cycle.gen)
      end
      cycle.idx = ((cycle.idx - 1 + step) % #cycle.list) + 1
      if SWITCHER_UI then
        switcher_ui(cycle) -- the switcher previews; focus moves on release
      else
        focus_address(cycle.list[cycle.idx])
      end
    end
  end

  for _, k in ipairs({ "SUPER + Super_L", "SUPER + Super_R", "SUPER + SHIFT + Super_L", "SUPER + SHIFT + Super_R" }) do
    hl.bind(k, commit_cycle, { release = true })
  end

  -------------------------------------------------------------------------
  -- ⌘ + letter
  -------------------------------------------------------------------------

  local cmd_letter = {
    A = { terminal = CS("A") },
    D = { terminal = CS("O") },                       -- split right (Mac Ghostty ⌘D)
    F = { terminal = CS("F") },
    H = { default = minimize, terminal = minimize },  -- hide
    K = { terminal = CS("K") },                       -- clear screen
    M = { default = minimize, terminal = minimize },  -- minimize
    N = { terminal = CS("N") },
    Q = { default = quit_app, terminal = quit_app, raw = quit_app },
    T = { terminal = CS("T") },
    W = { default = close_tab_or_window, terminal = CS("W") },
    Y = { browser = C("H") },                         -- history
  }

  local cmd_shift_letter = {
    D = { terminal = CS("E") },                       -- split down
    G = { files = C("L") },                           -- go to folder
    H = { browser = A("Home"), files = A("Home") },   -- home
    J = { chromium = C("J"), firefox = CS("Y") },     -- downloads
    N = { firefox = CS("P") },                        -- private window
    P = { terminal = CS("P") },                       -- command palette
    Q = { default = exec("omarchy-menu toggle system"), terminal = exec("omarchy-menu toggle system") },
    W = { default = close_window, browser = CS("W"), terminal = close_window },
  }

  for code = string.byte("A"), string.byte("Z") do
    local L = string.char(code)
    if L ~= "C" and L ~= "V" and L ~= "X" then -- Omarchy's universal clipboard keeps these
      local spec = cmd_letter[L] or {}
      if spec.default == nil then spec.default = C(L) end
      map("SUPER + " .. L, "⌘" .. L, spec)
    end
    local sspec = cmd_shift_letter[L] or {}
    if sspec.default == nil then sspec.default = CS(L) end
    map("SUPER + SHIFT + " .. L, "⌘⇧" .. L, sspec)
  end

  -------------------------------------------------------------------------
  -- ⌘ + numbers and punctuation (keycodes, so any layout works)
  -------------------------------------------------------------------------

  for n = 1, 9 do
    map("SUPER + code:" .. (n + 9), "⌘" .. n .. " (tab " .. n .. ")", { default = C(tostring(n)), terminal = A(tostring(n)) })
  end
  map("SUPER + code:19", "⌘0 actual size", { default = C("0"), terminal = C("0") })
  map("SUPER + code:20", "⌘- zoom out", { default = C("minus"), terminal = C("minus") }, { repeating = true })
  map("SUPER + code:21", "⌘= zoom in", { default = C("equal"), terminal = C("equal") }, { repeating = true })
  map("SUPER + SHIFT + code:21", "⌘+ zoom in", { default = C("equal"), terminal = C("equal") }, { repeating = true })
  map("SUPER + code:34", "⌘[ back", { browser = A("Left"), files = A("Left"), default = C("bracketleft") })
  map("SUPER + code:35", "⌘] forward", { browser = A("Right"), files = A("Right"), default = C("bracketright") })
  map("SUPER + SHIFT + code:34", "⌘⇧[ previous tab", { default = C("Prior"), terminal = C("Prior") })
  map("SUPER + SHIFT + code:35", "⌘⇧] next tab", { default = C("Next"), terminal = C("Next") })
  map("SUPER + code:59", "⌘, settings", { default = C("comma"), terminal = C("comma") })
  map("SUPER + SHIFT + code:59", "⌘⇧, reload config", { default = CS("comma"), terminal = CS("comma") })
  map("SUPER + code:60", "⌘. cancel", { default = K("Escape"), terminal = C("C") })
  map("SUPER + code:61", "⌘/ comment", { default = C("slash") })
  map("SUPER + code:49", "⌘` next window of app", { default = same_app_window(1), terminal = same_app_window(1) })
  map("SUPER + SHIFT + code:49", "⌘⇧` previous window of app", { default = same_app_window(-1), terminal = same_app_window(-1) })
  map("SUPER + RETURN", "⌘⏎ submit", { default = C("Return"), terminal = C("Return") })
  map("SUPER + SHIFT + RETURN", "⌘⇧⏎", { default = CS("Return"), terminal = CS("Return") })

  -------------------------------------------------------------------------
  -- ⌘⌥ combos
  -------------------------------------------------------------------------

  map("SUPER + ALT + I", "⌘⌥I developer tools", { browser = CS("I"), terminal = CS("I") })
  map("SUPER + ALT + J", "⌘⌥J JavaScript console", { browser = CS("J") })
  map("SUPER + ALT + C", "⌘⌥C inspect element", { browser = CS("C") })
  map("SUPER + ALT + U", "⌘⌥U view source", { browser = C("U") })
  map("SUPER + ALT + B", "⌘⌥B bookmarks manager", { browser = CS("O") })
  map("SUPER + ALT + K", "⌘⌥K web console / tmux keys", {
    firefox = CS("K"), default = exec("omarchy-menu-tmux-keybindings"), terminal = exec("omarchy-menu-tmux-keybindings"),
  })
  map("SUPER + ALT + F", "⌘⌥F find and replace", { editor = C("H") })
  map("SUPER + ALT + SHIFT + V", "⌘⌥⇧V paste and match style", { default = CS("V") })
  map("SUPER + ALT + LEFT", "⌘⌥← previous tab", { default = C("Prior"), terminal = CA("Left") })
  map("SUPER + ALT + RIGHT", "⌘⌥→ next tab", { default = C("Next"), terminal = CA("Right") })
  map("SUPER + ALT + UP", "⌘⌥↑", { terminal = CA("Up") })
  map("SUPER + ALT + DOWN", "⌘⌥↓", { terminal = CA("Down") })
  map("SUPER + ALT + ESCAPE", "⌘⌥⎋ force quit (click a window)", {
    default = exec("hyprctl kill"), terminal = exec("hyprctl kill"), raw = exec("hyprctl kill"),
  })
  map("SUPER + ALT + D", "⌘⌥D show/hide bar", { default = exec("omarchy-toggle-bar"), terminal = exec("omarchy-toggle-bar") })

  -------------------------------------------------------------------------
  -- Text navigation
  -------------------------------------------------------------------------

  local rep = { repeating = true }
  map("SUPER + LEFT", "⌘← line start", { default = K("Home"), terminal = C("A") }, rep)
  map("SUPER + RIGHT", "⌘→ line end", { default = K("End"), terminal = C("E") }, rep)
  map("SUPER + UP", "⌘↑ top", { default = C("Home"), files = A("Up"), terminal = CS("Prior") }, rep)
  map("SUPER + DOWN", "⌘↓ bottom", { default = C("End"), files = K("Return"), terminal = CS("Next") }, rep)
  map("SUPER + SHIFT + LEFT", "⌘⇧← select to line start", { default = S("Home") })
  map("SUPER + SHIFT + RIGHT", "⌘⇧→ select to line end", { default = S("End") })
  map("SUPER + SHIFT + UP", "⌘⇧↑ select to top", { default = CS("Home") })
  map("SUPER + SHIFT + DOWN", "⌘⇧↓ select to bottom", { default = CS("End") })
  map("SUPER + BACKSPACE", "⌘⌫ delete to line start", {
    default = seq(S("Home"), K("BackSpace")), files = K("Delete"), terminal = C("U"),
  })
  map("ALT + LEFT", "⌥← word left", { default = C("Left"), terminal = A("B") }, rep)
  map("ALT + RIGHT", "⌥→ word right", { default = C("Right"), terminal = A("F") }, rep)
  map("ALT + SHIFT + LEFT", "⌥⇧← select word left", { default = CS("Left") }, rep)
  map("ALT + SHIFT + RIGHT", "⌥⇧→ select word right", { default = CS("Right") }, rep)
  map("ALT + BACKSPACE", "⌥⌫ delete word", { default = C("BackSpace"), terminal = A("BackSpace") }, rep)
  map("ALT + Delete", "⌥⌦ delete word forward", { default = C("Delete"), terminal = A("D") }, rep)

  -- Physical ⌃ keys behave like Cocoa text fields; terminals get them untouched.
  if EMACS_CTRL_KEYS then
    local emacs = {
      A = K("Home"), E = K("End"), F = K("Right"), B = K("Left"), N = K("Down"), P = K("Up"),
      D = K("Delete"), H = K("BackSpace"), K = seq(S("End"), K("Delete")),
    }
    for letter, action in pairs(emacs) do
      map("CTRL + " .. letter, "⌃" .. letter .. " (Mac text editing)", { default = action, terminal = C(letter) }, rep)
    end
  end

  -------------------------------------------------------------------------
  -- Windows, workspaces and system shortcuts
  -------------------------------------------------------------------------

  map("SUPER + TAB", "⌘Tab switch windows", { default = app_switch(1), terminal = app_switch(1), raw = app_switch(1) })
  map("SUPER + SHIFT + TAB", "⌘⇧Tab switch windows backwards", {
    default = app_switch(-1), terminal = app_switch(-1), raw = app_switch(-1),
  })

  local function bind(keys, description, dispatcher, opts)
    pcall(hl.unbind, keys)
    opts = opts or {}
    opts.description = description
    if type(dispatcher) == "string" then dispatcher = hl.dsp.exec_cmd(dispatcher) end
    hl.bind(keys, dispatcher, opts)
  end

  bind("SUPER + SHIFT + code:12", "⌘⇧3 screenshot screen", "omarchy-capture-screenshot fullscreen")
  bind("SUPER + SHIFT + code:13", "⌘⇧4 screenshot region", "omarchy-capture-screenshot region")
  bind("SUPER + SHIFT + code:14", "⌘⇧5 capture menu", "omarchy-menu toggle capture")
  bind("SUPER + CTRL + SHIFT + code:12", "⌃⌘⇧3 screenshot screen", "omarchy-capture-screenshot fullscreen")
  bind("SUPER + CTRL + SHIFT + code:13", "⌃⌘⇧4 screenshot region", "omarchy-capture-screenshot region")
  bind("SUPER + CTRL + Q", "⌃⌘Q lock screen", "omarchy-system-lock")
  bind("SUPER + CTRL + SPACE", "⌃⌘Space emoji", "omarchy-shell shell toggle omarchy.emojis")
  bind("CTRL + ALT + M", "⌃⌥M show minimized windows", hl.dsp.workspace.toggle_special("minimized"))

  -- Mission Control: ⌃↑ and the F3 key open the workspace overview.
  bind("CTRL + UP", "⌃↑ workspace overview", "omarchy-shell omacmdOverview toggle")
  bind("XF86LaunchA", "Mission Control key: workspace overview", "omarchy-shell omacmdOverview toggle")

  -- Workspaces like Spaces: ⌃←/→ switch, ⌃⇧←/→ carry the window along.
  bind("CTRL + LEFT", "⌃← previous workspace", hl.dsp.focus({ workspace = "e-1" }))
  bind("CTRL + RIGHT", "⌃→ next workspace", hl.dsp.focus({ workspace = "e+1" }))
  bind("CTRL + SHIFT + LEFT", "⌃⇧← move window to previous workspace", hl.dsp.window.move({ workspace = "r-1" }))
  bind("CTRL + SHIFT + RIGHT", "⌃⇧→ move window to next workspace", hl.dsp.window.move({ workspace = "r+1" }))

  -- ⌘⌥1..0 sends the window to a workspace (from translate.lua); add ⇧ to go with it.
  for n = 1, 10 do
    bind("SUPER + ALT + SHIFT + code:" .. (n + 9), "⌘⌥⇧" .. (n % 10) .. " move window to workspace " .. n .. " and follow",
      hl.dsp.window.move({ workspace = tostring(n) }))
  end

  -- ⌘-click opens links in a new tab: a click becomes ⌃-click, a drag still moves the window.
  if CMD_CLICK then
    hl.config({ binds = { drag_threshold = 10 } })
    pcall(hl.unbind, "SUPER + mouse:272")
    hl.bind("SUPER + mouse:272", function()
      hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "mouse:272" }))
    end, { click = true, description = "⌘-click (sent as ⌃-click)" })
    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window (⌘-drag)" })
  end

  -- Trackpad: three fingers switch workspaces, four fingers up/down open/close the overview.
  if GESTURES then
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({ fingers = 4, direction = "up", action = function() hl.exec_cmd("omarchy-shell omacmdOverview open") end })
    hl.gesture({ fingers = 4, direction = "down", action = function() hl.exec_cmd("omarchy-shell omacmdOverview close") end })
    hl.config({
      gestures = {
        workspace_swipe_distance = option("swipe_distance", 1000), -- finger travel per workspace
        workspace_swipe_cancel_ratio = 0.25,                       -- a quarter swipe commits
        workspace_swipe_min_speed_to_force = 15,                   -- a quick flick switches
        workspace_swipe_create_new = false,                        -- stop at the last workspace
      },
    })
  end

  -------------------------------------------------------------------------
  -- Personal additions from ~/.config/hypr/omacmd.lua
  -------------------------------------------------------------------------

  if type(cfg.after) == "function" then
    cfg.after({ map = map, bind = bind, press = press, exec = exec,
      K = K, C = C, CS = CS, A = A, S = S, CA = CA, seq = seq })
  end
end
