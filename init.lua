log = hs.logger.new("jer", "info")
log.i("loading")

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
local Tweetbot = "com.tapbots.Tweetbot3Mac"
local Zoom = "us.zoom.xos"
local Safari = "com.apple.Safari"

function makeTweetbotUrl(url)
  local u = url
  local u = string.gsub(u, "https?://www%.twitter%.com", "")
  local u = string.gsub(u, "https?://mobile%.twitter%.com", "")
  local u = string.gsub(u, "https?://twitter%.com", "")
  local u = string.gsub(u, "#!/", "")
  local u = string.gsub(u, "/statuses/", "/status/")

  if string.match(u, "/status/", 1, true) then
    return "tweetbot:/" .. u
  elseif string.match(u, "^/[%w_]+/?$") then
    return "tweetbot:/user_profile" .. u
  elseif string.match(u, "^/search%?") then
    return "tweetbot:" .. string.gsub(u, "q=", "query=")
  else
    return url
  end
end

function tweetbot(url)
  local newUrl = makeTweetbotUrl(url)
  log.i("newUrl", newUrl)
  if newUrl == url then
    hs.urlevent.openURLWithBundle(url, DefaultBrowser)
  else
    hs.urlevent.openURLWithBundle(newUrl, Tweetbot)
  end
end

installAndUse("URLDispatcher", {
  config = {
    url_patterns = {
      {"https?://zoom.us/j/",           Zoom},
      {"https?://%w+.zoom.us/j/",       Zoom},
      {"https?://app.slack.com/",       Safari},
      {"https?://docs.google.com",      DefaultBrowser},
      {"https?://bugzilla.mozilla.org", DefaultBrowser},
      {"https?://mobile.twitter.com",   nil, tweetbot},
      {"https?://twitter.com",          nil, tweetbot},
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

hs.hotkey.bind(hyper, "1", function()
  mKey("brightness_down")
end)

hs.hotkey.bind(hyper, "2", function()
  mKey("brightness_up")
end)

hs.hotkey.bind(hyper, "-", function()
  mKey("sound_down")
end)

hs.hotkey.bind(hyper, "=", function()
  mKey("sound_up")
end)

hs.hotkey.bind(hyper, "8", function()
  mKey("play")
end)

-- Focus Calendar
hs.hotkey.bind(hyper, "b", function()
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
    log.i("title is still "..title)
    hs.timer.usleep(500 * 1000) -- wait 500ms
    title = hs.pasteboard.readString()
    runs = runs + 1
  end

  if title == nil or title == url then
    hs.notify.new({title="Markdown URL", informativeText="No title copied. Abort."}):send()
    return
  end

  md = "[" .. title .. "](" .. url .. ")"
  hs.pasteboard.setContents(md)
  hs.notify.new({title="Markdown URL", informativeText="Copied Markdown-formatted URL to clipboard."}):send()
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
  local builtin = hs.screen.find("Color LCD")
  window:moveToScreen(builtin)
  window:setSize(hs.geometry.size(1085, 760))
end)
