local padding = 5


hs.hotkey.bind({"cmd", "shift"}, "/", function()
  hs.application.open("kitty.app")
end)

hs.hotkey.bind({"cmd", "shift"}, "return", function()
  hs.application.open("Brave Browser.app")
end)

hs.hotkey.bind({"cmd", "shift"}, "y", function()
  hs.application.open("Messages.app")
end)

hs.hotkey.bind({"cmd", "shift"}, "u", function()
  hs.application.open("Slack.app")
end)

hs.hotkey.bind({"cmd", "shift"}, ",", function()
  hs.application.open("Insomnia.app")
end)

hs.hotkey.bind({"cmd", "shift"}, ".", function()
  hs.application.open("Visual Studio Code.app")
end)

hs.hotkey.bind({"cmd", "shift"}, "a", function()
  hs.application.open("Authy Desktop.app")
end)

hs.hotkey.bind({"cmd", "shift"}, "m", function()
  hs.application.open("Microsoft Outlook.app")
end)

hs.hotkey.bind({"cmd", "shift"}, "b", function()
  hs.application.open("Music.app")
end)

hs.hotkey.bind({"cmd", "shift"}, "\\", function()
  hs.application.open("Zoom.us.app")
end)


-- windows
hs.hotkey.bind({"cmd", "shift"}, "9", function()
  -- left half
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + padding
  f.y = max.y + padding
  f.w = (max.w / 2) - padding - (padding /2)
  f.h = max.h - (padding * 2)
  win:setFrame(f)
end)

hs.hotkey.bind({"cmd", "shift"}, "0", function()
  -- right half
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2) + (padding / 2)
  f.y = max.y + padding
  f.w = (max.w / 2) - padding - (padding /2)
  f.h = max.h - (padding * 2)
  win:setFrame(f)
end)

hs.hotkey.bind({"cmd", "shift"}, "=", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + padding
  f.y = max.y + padding
  f.w = max.w - (padding * 2)
  f.h = max.h - (padding * 2)
  win:setFrame(f)
end)



hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Config loaded")
