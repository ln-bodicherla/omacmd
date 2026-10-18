-- Offline tests: `lua tests/run.lua` from the repo root. Hyprland is stubbed.
local root = (arg[0]:match("^(.*)/tests/") or ".") .. "/"
local failures, count = 0, 0

local function check(name, got, want)
  count = count + 1
  if got ~= want then
    failures = failures + 1
    print(("FAIL %s\n     got:  %s\n     want: %s"):format(name, tostring(got), tostring(want)))
  end
end

-- Translator ---------------------------------------------------------------

local T = dofile(root .. "hypr/translate.lua")
local cases = {
  { "SUPER + W", false },
  { "SUPER + Q", false },
  { "SUPER + F", "SUPER + CTRL + F" },
  { "SUPER + RETURN", "SUPER + CTRL + ALT + T" },
  { "SUPER + T", "CTRL + ALT + T" },
  { "SUPER + LEFT", "CTRL + ALT + LEFT" },
  { "SUPER + code:12", "CTRL + code:12" },
  { "SUPER + code:20", "CTRL + ALT + code:20" },
  { "SUPER + comma", "CTRL + ALT + comma" },
  { "SUPER + SHIFT + code:12", "CTRL + SHIFT + code:12" },
  { "SUPER + SHIFT + LEFT", "CTRL + ALT + SHIFT + LEFT" },
  { "SUPER + SHIFT + B", "SUPER + CTRL + ALT + B" },
  { "SUPER + SHIFT + RETURN", "SUPER + CTRL + ALT + RETURN" },
  { "SUPER + SHIFT + ALT + B", "SUPER + CTRL + ALT + SHIFT + B" },
  { "SUPER + ALT + SHIFT + code:13", "SUPER + ALT + code:13" },
  { "SUPER + ALT + code:10", "SUPER + CTRL + ALT + code:10" },
  { "SUPER + ALT + F", "CTRL + ALT + RETURN" },
  { "SUPER + ALT + S", "CTRL + ALT + SHIFT + S" },
  { "SUPER + CTRL + F", "CTRL + ALT + F" },
  { "SUPER + CTRL + SPACE", "SUPER + CTRL + ALT + SPACE" },
  { "SUPER + CTRL + ALT + B", "CTRL + ALT + SHIFT + B" },
  -- left alone
  { "SUPER + C", "SUPER + C" },
  { "SUPER + V", "SUPER + V" },
  { "SUPER + SPACE", "SUPER + SPACE" },
  { "SUPER + SHIFT + SPACE", "SUPER + SHIFT + SPACE" },
  { "SUPER + ALT + SPACE", "SUPER + ALT + SPACE" },
  { "SUPER + SHIFT + CTRL + G", "SUPER + SHIFT + CTRL + G" },
  { "SUPER + mouse:272", "SUPER + mouse:272" },
  { "ALT + TAB", "ALT + TAB" },
  { "XF86AudioMute", "XF86AudioMute" },
}
for _, c in ipairs(cases) do
  check("translate " .. c[1], T.translate(c[1]), c[2])
end

-- Omarchy's real default bindings never collide after translation.
local omarchy = os.getenv("OMARCHY_PATH") or "/usr/share/omarchy"
local sources = {}
local list = io.popen("cat " .. omarchy .. "/default/hypr/bindings/*.lua " .. omarchy .. "/default/hypr/*.lua 2>/dev/null")
for line in list:lines() do
  local keys = line:match('^%s*o%.bind%(%s*"([^"]+)"') or line:match('^%s*o%.bind_toggle%(%s*"([^"]+)"')
  local prefix = line:match('^%s*o%.bind%(%s*"([^"]+)"%s*%.%.%s*key')
  if prefix then
    for code = 10, 19 do sources[#sources + 1] = prefix .. "code:" .. code end
  elseif keys then
    sources[#sources + 1] = keys
  end
end
list:close()
local seen = {}
for _, s in ipairs(sources) do
  local t = T.translate(s)
  if t then
    local norm = t:upper():gsub("%s", "")
    count = count + 1
    if seen[norm] and seen[norm] ~= s:upper():gsub("%s", "") then
      failures = failures + 1
      print(("FAIL collision: %s and %s both -> %s"):format(seen[norm], s, t))
    end
    seen[norm] = seen[norm] or s:upper():gsub("%s", "")
  end
end
check("found Omarchy bindings to test", #sources > 100 or #sources == 0, true)

-- keys.lua loads against a stub and binds what it promises -------------------

local binds = {}
local function dsp() return setmetatable({}, { __index = function() return function() return {} end end }) end
hl = {
  bind = function(keys, _, opts) binds[#binds + 1] = { keys = keys, opts = opts or {} } end,
  unbind = function() end,
  on = function() return { remove = function() end } end,
  timer = function() end, dispatch = function() end, exec_cmd = function() end,
  config = function() end, gesture = function() end,
  get_layers = function() return {} end, get_windows = function() return {} end,
  get_active_window = function() return nil end, is_key_down = function() return false end,
  dsp = setmetatable({ window = dsp(), workspace = dsp() }, { __index = function() return function() return {} end end }),
}

local after_called = false
dofile(root .. "hypr/keys.lua")({ after = function(mk) after_called = mk.map ~= nil end }, root .. "hypr/")

local by_desc = {}
for _, b in ipairs(binds) do
  if b.opts.description then by_desc[b.opts.description] = b.keys end
end
check("⌘T bound", by_desc["⌘T"], "SUPER + T")
check("⌘C left to Omarchy", by_desc["⌘C"], nil)
check("⌘Tab bound", by_desc["⌘Tab switch windows"], "SUPER + TAB")
check("⌥← bound", by_desc["⌥← word left"], "ALT + LEFT")
check("⌃⇧→ bound", by_desc["⌃⇧→ move window to next workspace"], "CTRL + SHIFT + RIGHT")
check("⌘-click bound", by_desc["⌘-click (sent as ⌃-click)"], "SUPER + mouse:272")
check("after() hook ran", after_called, true)

local dup = {}
for _, b in ipairs(binds) do
  local k = b.keys .. (b.opts.release and " (release)" or "") .. (b.opts.click and " (click)" or "") .. (b.opts.mouse and " (mouse)" or "")
  count = count + 1
  if dup[k] then
    failures = failures + 1
    print("FAIL bound twice: " .. k)
  end
  dup[k] = true
end

print(("%d checks, %d failures"):format(count, failures))
os.exit(failures == 0 and 0 or 1)
