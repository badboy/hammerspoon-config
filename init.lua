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
  hs.reload()
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

function volume(param, symbol)
  local output = hs.audiodevice.defaultOutputDevice()
  if output ~= nil then
    local current = math.floor(output:outputVolume() + 0.5)
    local newVol
    if param == "down" then
      newVol = current - 5
    else
      newVol = current + 5
    end
    if newVol <= 0 then
      newVol = 0
      symbol = "🔈"
    elseif newVol > 100 then
      newVol = 100
    end

    output:setVolume(newVol)
    local on = math.floor(newVol/10 + 0.5)
    local off = 10 - on
    local level = string.rep("⚫️", on)
    local levelOff = string.rep("⚪️", off)
    local msg = symbol .. " " .. level .. levelOff

    hs.alert.show(msg, {atScreenEdge = 2, fadeInDuration=0, fadeOutDuration=0, fillColor={white=0, alpha=1}})
  end
end

hs.hotkey.bind(hyper, "8", function()
  volume("down", "🔉")
end)

hs.hotkey.bind(hyper, "9", function()
  volume("up", "🔊")
end)
