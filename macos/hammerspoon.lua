local padding = 5

local appModalBindings = {
  { "h", "Music.app" },
  { "u", "Slack.app" },
  { "l", "Microsoft Teams.app" },
  { "t", "Reminders.app" },
  { "'", "Insomnia.app" },
  { "p", "Obsidian.app" },
  { "return", "Brave Browser.app" },
  { "o", "Visual Studio Code.app" },
  { "m", "Microsoft Outlook.app" },
  { "y", "Messages.app" },
  { "\\", "Zoom.us.app" },
  { "/", "kitty.app" },
}

local lastWindowId

function pushWindowToRecent()
  local focusedWindow = hs.window.focusedWindow()
  lastWindowId = focusedWindow:id()
end

function swapFocusWithLastWindow()
  if lastWindowId == nil then
    return
  end

  local focusedWindow = hs.window.focusedWindow()
  local currentWindowId = focusedWindow:id()
  local lastWindow = hs.window.get(lastWindowId)
  lastWindow:focus()
  lastWindowId = currentWindowId
end

hs.hotkey.bind({ "cmd", "shift" }, "/", function()
  pushWindowToRecent()
  hs.application.launchOrFocus("kitty.app")
end)

function bindAppModal(modal, key, app)
  modal:bind("", key, function()
    pushWindowToRecent()
    hs.application.launchOrFocus(app)
    modal:exit()
  end)
end

function initModal()
  local appModal = hs.hotkey.modal.new({ "cmd", "shift" }, "space")
  appModal:bind("", "escape", function()
    appModal:exit()
  end)
  appModal:bind("", "space", function()
    swapFocusWithLastWindow()
    appModal:exit()
  end)
  for i, keyApp in ipairs(appModalBindings) do
    bindAppModal(appModal, keyApp[1], keyApp[2])
  end
end

-- windows
hs.hotkey.bind({ "cmd", "shift" }, "9", function()
  -- left half
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + padding
  f.y = max.y + padding
  f.w = (max.w / 2) - padding - (padding / 2)
  f.h = max.h - (padding * 2)
  win:setFrame(f)
end)

hs.hotkey.bind({ "cmd", "shift" }, "0", function()
  -- right half
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  f.x = max.x + (max.w / 2) + (padding / 2)
  f.y = max.y + padding
  f.w = (max.w / 2) - padding - (padding / 2)
  f.h = max.h - (padding * 2)
  win:setFrame(f)
end)

hs.hotkey.bind({ "cmd", "shift" }, "=", function()
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

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
  hs.reload()
end)

initModal()

hs.alert.show("Config loaded")
