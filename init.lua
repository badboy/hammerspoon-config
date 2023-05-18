log = hs.logger.new("jer", "info")
log.i("loading")

-- Trim whitespace of a string, front and back.
function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

hyper = {"cmd", "ctrl", "shift"}

-- Convenience function to use spoons
function installAndUse(name, args)
  local s = hs.loadSpoon("SpoonInstall")
  s.use_syncinstall = true
  s:andUse(name, args)
end

-- Reload
hs.hotkey.bind(hyper, "0", function()
  hs.alert.show("Reloading Hammerspoon config.", {atScreenEdge = 2})
  -- .reload() kills the Lua engine and restarts it.
  --  We need to give a bit of time to show the message.
  hs.timer.doAfter(1, function()
    hs.reload()
  end)
end)

-- Highlight Mouse
installAndUse("MouseCircle", { hotkeys = { show = {hyper, "M"}}})

local DefaultBrowser = "org.mozilla.nightly"
local Zoom = "us.zoom.xos"
local Safari = "com.apple.Safari"

installAndUse("URLDispatcher", {
  config = {
    url_patterns = {
      {"^https?://zoom.us/j/",           Zoom},
      {"^https?://%w+.zoom.us/j/",       Zoom},
      {"^https?://app.slack.com/",       Safari},
      {"^https?://docs.google.com",      DefaultBrowser},
      {"^https?://bugzilla.mozilla.org", DefaultBrowser},
    },
    default_handler = DefaultBrowser,
  },
  start = true
})

-- Simulates pressing a multimedia key on a keyboard
-- Takes the key string and simulates pressing it for 5 ms then releasing it.
function mKey(key)
  local key = string.upper(key)
  hs.eventtap.event.newSystemKeyEvent(key, true):post()
  hs.timer.usleep(5)
  hs.eventtap.event.newSystemKeyEvent(key, false):post()
end

hs.hotkey.bind({}, hs.keycodes.map["F1"], function()
  mKey("brightness_down")
end)

hs.hotkey.bind({}, hs.keycodes.map["F2"], function()
  mKey("brightness_up")
end)

hs.hotkey.bind({}, hs.keycodes.map["F5"], function()
  mKey("illumination_down")
end)

hs.hotkey.bind({}, hs.keycodes.map["F6"], function()
  mKey("illumination_up")
end)

hs.hotkey.bind({}, hs.keycodes.map["F7"], function()
  print(hs.execute("/Users/jer/.nix-profile/bin/mpc prev"))
end)

hs.hotkey.bind({}, hs.keycodes.map["F8"], function()
  print(hs.execute("/Users/jer/.nix-profile/bin/mpc toggle"))
end)

hs.hotkey.bind({}, hs.keycodes.map["F9"], function()
  print(hs.execute("/Users/jer/.nix-profile/bin/mpc next"))
end)

hs.hotkey.bind({}, hs.keycodes.map["F11"], function()
  mKey("sound_down")
end)

hs.hotkey.bind({}, hs.keycodes.map["F12"], function()
  mKey("sound_up")
end)

-- Focus Calendar
hs.hotkey.bind(hyper, "v", function()
  hs.application.launchOrFocus("Calendar")
end)

-- Focus Mail
hs.hotkey.bind(hyper, "n", function()
  hs.application.launchOrFocus("Thunderbird")
end)

-- Format URL & title into Markdown link
hs.hotkey.bind(hyper, "c", function()
  local url = hs.pasteboard.readString()
  if url == nil then
    hs.notify.new({title="Markdown URL", informativeText="Couldn't get text from clipboard"}):send()
    return
  end

  hs.notify.new({title="Markdown URL", informativeText="URL copied. Now copy the title."}):send()

  local title = hs.pasteboard.readString()
  local runs = 0
  while title ~= nil and title == url and runs < 10 do -- wait a maximum of 10*500ms = 5s
    hs.timer.usleep(500 * 1000) -- wait 500ms
    title = hs.pasteboard.readString()
    runs = runs + 1
  end

  title = trim(title)
  url = trim(url)

  if title == nil or title == url then
    hs.notify.new({title="Markdown URL", informativeText="No title copied. Abort."}):send()
    return
  end

  md = "[" .. title .. "](" .. url .. ")"
  hs.pasteboard.setContents(md)
  hs.notify.new({title="Markdown URL", informativeText="Copied Markdown-formatted URL to clipboard."}):send()
end)

-- Format text in clipboard as todo item
hs.hotkey.bind(hyper, "t", function()
  local text = hs.pasteboard.readString()
  if text == nil then
    hs.notify.new({title="Todo Item", informativeText="Couldn't get text from clipboard"}):send()
    return
  end

  md = "* [ ] " .. trim(text)
  hs.pasteboard.setContents(md)
  hs.notify.new({title="Todo Item", informativeText="Copied Markdown-formatted todo item."}):send()
end)

-- Open copied URLs in the default browser.
--
-- Useful when some apps only offer to open in the configured default browser,
-- which is now hammerspoon itself, but you actually want it in e.g. Firefox.
hs.hotkey.bind(hyper, "o", function()
  local url = hs.pasteboard.readString()
  if string.match(url, "http") then
    if string.match(url, "https?://zoom.us/j/") or string.match(url, "https?://%w+.zoom.us/j/") then
      hs.urlevent.openURLWithBundle(url, Zoom)
    elseif string.match(url, "https?://app.slack.com/") then
      hs.urlevent.openURLWithBundle(url, Safari)
    else
      hs.urlevent.openURLWithBundle(url, DefaultBrowser)
    end
  end
end)

-- Always move new Zoom windows to the MBP screen
local wf = hs.window.filter
local zoomWins = wf.new(false):setAppFilter('zoom.us')
zoomWins:subscribe(wf.windowCreated, function(window)
  -- https://www.hammerspoon.org/docs/hs.screen.html#find
  local builtin = hs.screen{x=-1,y=0}
  window:moveToScreen(builtin)
  window:setSize(hs.geometry.size(1085, 760))
  --window:setTopLeft(hs.geometry.point(-1300, 644))
end)

function alignSonosCantata()
  local sonosPos = nil
  local cantataPos = nil
  local space = 1
  local single = false
  -- Only one screen = internal screen = smaller.
  if #hs.screen.allScreens() == 1 then
    sonosPos = {100, 150}
    cantataPos = {250, 70}
    screen = 1
    single = true
  else
    sonosPos = {-1340, 730}
    cantataPos = {-1200, 644}
    screen = hs.screen.find('Built%-in')
  end

  local sonosApp = hs.application.applicationsForBundleID("com.sonos.macController2")
  if #sonosApp > 0 then
    sonosWindow = wf.new(false):setAppFilter(sonosApp[1]:name()):getWindows()[1]
    if single then
      hs.spaces.moveWindowToSpace(sonosWindow, screen)
    else
      sonosWindow:moveToScreen(screen)
    end
    sonosWindow:setTopLeft(hs.geometry.point(sonosPos[1], sonosPos[2]))
  end

  local cantataApp = hs.application.applicationsForBundleID("mpd.cantata")
  if #cantataApp == 0 then return end

  cantataWindow = wf.new(false):setAppFilter(cantataApp[1]:name()):getWindows()[1]
  if single then
    hs.spaces.moveWindowToSpace(cantataWindow, screen)
  else
    cantataWindow:moveToScreen(screen)
  end
  cantataWindow:setTopLeft(hs.geometry.point(cantataPos[1], cantataPos[2]))
  cantataWindow:setSize(hs.geometry(nil, nil, 970, 650))
  cantataWindow:raise()
end

-- Position Sonos & Cantata Window correctly on second screen
hs.hotkey.bind(hyper, ";", function()
  alignSonosCantata()
end)
