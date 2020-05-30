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

hs.hotkey.bind(hyper, "1", function()
  hs.execute("/usr/local/bin/cliclick kp:brightness-down ws:500")
end)

hs.hotkey.bind(hyper, "2", function()
  hs.execute("/usr/local/bin/cliclick kp:brightness-up ws:500")
end)

hs.hotkey.bind(hyper, "-", function()
  hs.execute("/usr/local/bin/cliclick kp:volume-down ws:500")
end)

hs.hotkey.bind(hyper, "=", function()
  hs.execute("/usr/local/bin/cliclick kp:volume-up ws:500")
end)
