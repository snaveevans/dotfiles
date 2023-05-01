local padding = 5

local appModalBindings = {
  { "h", "Music.app" },
  { "j", "Google Chrome.app" },
  { "k", "Slack.app" },
  { "l", "Microsoft Teams.app" },
  { ";", "Authy Desktop.app" },
  { "'", "Insomnia.app" },
  { "o", "Visual Studio Code.app" },
  { "n", "Obsidian.app" },
  { "m", "Microsoft Outlook.app" },
  { "u", "Messages.app" },
  { "\\", "Zoom.us.app" },
  { "/", "kitty.app" },
}

hs.hotkey.bind({ "cmd", "shift" }, "/", function()
  hs.application.open("kitty.app")
end)

function bindAppShortcut(mods, key, app)
  hs.hotkey.bind(mods, key, function()
    hs.application.open(app)
  end)
end

function bindAppModal(modal, key, app)
  modal:bind("", key, function()
    hs.application.open(app)
    modal:exit()
  end)
end

function initModal()
  local appModal = hs.hotkey.modal.new({ "cmd", "shift" }, "space")
  appModal:bind("", "escape", function()
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
