-- macOS keys, part 1: move Omarchy's window-manager bindings off ⌘ (SUPER) so
-- ⌘ can mean what it means on a Mac inside apps. Hyprland is wrapped only while
-- Omarchy's defaults load, so package updates and new defaults are moved too.
--
-- Where things go:
--   ⌘ + window key (T J P O L G S K ` / , ⌫ - = arrows)  ->  ⌃⌥ + same key
--   ⌘ + 1..0 (workspaces)                                ->  ⌃ + 1..0   (Mac Spaces)
--   ⌘⇧ + 1..0 (move window)                              ->  ⌃⇧ + 1..0   (⌘⌥ + 1..0 sends it silently)
--   ⌘⇧ + letter / ⏎ / / (app launchers)                 ->  ⌃⌥⌘ + same key
--   ⌘⌥⇧ + letter (launcher variants)                    ->  ⌃⌥⌘⇧ + same key
--   ⌘ + F fullscreen                                     ->  ⌃⌘F  (Mac)
--   ⌘ + ⏎ terminal                                       ->  ⌃⌥⌘T
-- Toggle the whole thing with: mac-keys on|off
--
-- Loaded from ~/.config/hypr/hyprland.lua by the hook `mac-keys install` adds.
-- Personal settings live in ~/.config/hypr/mac-keys.lua (see config.example.lua).

local M = {}

local home = os.getenv("HOME") or ""
local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")

local disabled_flag = home .. "/.local/state/mac-keys/disabled"

function M.enabled()
  local f = io.open(disabled_flag, "r")
  if f then
    f:close()
    return false
  end
  return true
end

local MOD_ORDER = { "SUPER", "CTRL", "ALT", "SHIFT" }
local ARROW = { LEFT = true, RIGHT = true, UP = true, DOWN = true }

local function parse(keys)
  local mods, key = {}, nil
  for raw in keys:gmatch("[^+]+") do
    local part = raw:match("^%s*(.-)%s*$")
    local up = part:upper()
    if up == "CONTROL" then
      up = "CTRL"
    end
    if up == "SUPER" or up == "CTRL" or up == "ALT" or up == "SHIFT" then
      mods[up] = true
    elseif part ~= "" then
      key = part
    end
  end
  return mods, key
end

local function signature(mods)
  local out = {}
  for _, m in ipairs(MOD_ORDER) do
    if mods[m] then
      out[#out + 1] = m
    end
  end
  return table.concat(out, "+")
end

local function is_digit(k)
  local n = tonumber(k:match("^CODE:(%d+)$"))
  return n ~= nil and n >= 10 and n <= 19
end

local function is_resize(k)
  return k == "CODE:20" or k == "CODE:21"
end

local function is_letter(k)
  return k:match("^%u$") ~= nil
end

local WM_KEYS = { J = true, P = true, T = true, O = true, L = true, G = true, S = true, K = true,
  GRAVE = true, BACKSPACE = true, SLASH = true, COMMA = true }

-- Returns new signature (and optionally a new key), false to drop the binding,
-- or nil to keep it as it is.
local function rule(sig, K)
  if sig == "SUPER" then
    if K == "W" or K == "Q" then return false end -- replaced by Mac ⌘W / ⌘Q
    if K == "F" then return "SUPER+CTRL" end
    if K == "RETURN" then return "SUPER+CTRL+ALT", "T" end
    if is_digit(K) then return "CTRL" end
    if WM_KEYS[K] or ARROW[K] or is_resize(K) then return "CTRL+ALT" end
  elseif sig == "SUPER+SHIFT" then
    if is_digit(K) then return "CTRL+SHIFT" end
    if ARROW[K] or is_resize(K) or K == "GRAVE" or K == "BACKSPACE" or K == "COMMA" then return "CTRL+ALT+SHIFT" end
    if is_letter(K) or K == "RETURN" or K == "SLASH" then return "SUPER+CTRL+ALT" end
  elseif sig == "SUPER+ALT" then
    if is_digit(K) then return "SUPER+CTRL+ALT" end -- group tabs make room for window moves
    if K == "F" then return "CTRL+ALT", "RETURN" end
    if K == "G" or K == "S" or K == "SLASH" then return "CTRL+ALT+SHIFT" end
    if ARROW[K] or is_resize(K) then return "SUPER+CTRL+ALT" end
  elseif sig == "SUPER+ALT+SHIFT" then
    -- Silent window move goes to the easier ⌘⌥1..0 (Mac apps don't use it).
    if is_digit(K) then return "SUPER+ALT" end
    if is_resize(K) or is_letter(K) then return "SUPER+CTRL+ALT+SHIFT" end
  elseif sig == "SUPER+CTRL" then
    if K == "F" then return "CTRL+ALT" end
    if K == "Q" or K == "SPACE" then return "SUPER+CTRL+ALT" end
  elseif sig == "SUPER+CTRL+ALT" then
    -- Omarchy's info keys make room for the relocated launchers.
    if is_letter(K) or K == "DELETE" then return "CTRL+ALT+SHIFT" end
  end
  return nil
end

-- Exposed for tests: returns the translated key string, false, or the input.
function M.translate(keys)
  if type(keys) ~= "string" then
    return keys
  end
  local mods, key = parse(keys)
  if not key then
    return keys
  end
  local new_sig, new_key = rule(signature(mods), key:upper())
  if new_sig == false then
    return false
  elseif new_sig == nil then
    return keys
  end
  return new_sig:gsub("%+", " + ") .. " + " .. (new_key or key)
end

-- Survive config reloads: the Lua state persists, so keep the real functions once.
-- (`hl` is absent when the translator is loaded by the unit tests.)
if hl then
  _G.__mac_keys_orig = _G.__mac_keys_orig or { bind = hl.bind, unbind = hl.unbind }
end

function M.begin()
  if not M.enabled() then
    return
  end
  local orig = _G.__mac_keys_orig
  hl.bind = function(keys, ...)
    local k = M.translate(keys)
    if k == false then
      return nil
    end
    return orig.bind(k, ...)
  end
  hl.unbind = function(keys, ...)
    local k = M.translate(keys)
    if k == false then
      return nil
    end
    return orig.unbind(k, ...)
  end
end

function M.finish()
  hl.bind = _G.__mac_keys_orig.bind
  hl.unbind = _G.__mac_keys_orig.unbind
end

local function notify_error(what, err)
  hl.exec_cmd("omarchy-notification-send -u critical " .. string.format("%q", "mac-keys: " .. what) .. " "
    .. string.format("%q", tostring(err)))
end

-- Personal settings: ~/.config/hypr/mac-keys.lua returning a table.
function M.user_config()
  local path = home .. "/.config/hypr/mac-keys.lua"
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  f:close()
  local ok, cfg = pcall(dofile, path)
  if not ok or type(cfg) ~= "table" then
    notify_error("ignoring ~/.config/hypr/mac-keys.lua", ok and "it must return a table" or cfg)
    return {}
  end
  return cfg
end

function M.apply()
  if not M.enabled() then
    return
  end
  local ok, err = pcall(function()
    dofile(here .. "keys.lua")(M.user_config(), here)
  end)
  if not ok then
    notify_error("failed to load", err)
  end
end

return M
