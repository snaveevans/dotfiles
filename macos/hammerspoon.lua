local padding = 5
local appModal = nil

local appModalBindings = {
  { "h",      "Music.app" },
  { "u",      "Slack.app" },
  { "l",      "Microsoft Teams.app" },
  { "t",      "Reminders.app" },
  { "'",      "Insomnia.app" },
  { "p",      "Obsidian.app" },
  { "return", "Brave Browser.app" },
  { "i",      "IntellJ IDEA.app" },
  { "o",      "Visual Studio Code.app" },
  { "m",      "Microsoft Outlook.app" },
  { "y",      "Messages.app" },
  { "\\",     "Zoom.us.app" },
}

hs.hotkey.bind({ "cmd", "shift" }, "/", function()
  hs.application.launchOrFocus("kitty.app")
end)

function bindAppModal(modal, key, app)
  modal:bind("", key, function()
    if app == "Visual Studio Code.app" then
      modal:exit() -- Exit modal first
      showVSCodeWindowChooser()
    else
      hs.application.launchOrFocus(app)
      modal:exit()
    end
  end)
end

function showVSCodeWindowChooser()
  -- Try multiple possible names for VS Code
  local possibleNames = {
    "Visual Studio Code",
    "Code",
    "VSCode",
    "com.microsoft.VSCode"
  }

  local vscodeApp = nil
  for _, name in ipairs(possibleNames) do
    vscodeApp = hs.application.find(name)
    if vscodeApp then
      break
    end
  end

  -- If VS Code is not running, launch it
  if not vscodeApp then
    hs.application.launchOrFocus("Visual Studio Code.app")
    return
  end

  local windows = vscodeApp:allWindows()

  -- Filter out minimized windows
  local visibleWindows = {}
  for _, window in ipairs(windows) do
    if not window:isMinimized() then
      table.insert(visibleWindows, window)
    end
  end

  if #visibleWindows == 0 then
    -- If no visible windows, just focus the app (this will show any minimized windows)
    vscodeApp:activate()
    return
  end

  if #visibleWindows == 1 then
    -- If only one window, just focus it
    visibleWindows[1]:focus()
    return
  end

  -- Multiple windows - show the chooser
  local choices = {}
  for i, window in ipairs(visibleWindows) do
    local title = window:title()
    if title == "" or title == nil then
      title = "Untitled"
    end
    table.insert(choices, {
      text = title,
      subText = "VS Code Window " .. i,
      window = window
    })
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      choice.window:focus()
    end
  end)

  chooser:choices(choices)
  chooser:searchSubText(true)
  chooser:placeholderText("Select VS Code window...")

  -- Show the chooser first
  chooser:show()

  -- Add custom hotkeys for navigation while chooser is open
  local cmdNHotkey = hs.hotkey.bind({ "cmd" }, "n", function()
    local currentRow = chooser:selectedRow()
    local nextRow = (currentRow % #choices) + 1
    chooser:selectedRow(nextRow)
  end)

  local cmdPHotkey = hs.hotkey.bind({ "cmd" }, "p", function()
    local currentRow = chooser:selectedRow()
    local prevRow = currentRow == 1 and #choices or currentRow - 1
    chooser:selectedRow(prevRow)
  end)

  -- Clean up hotkeys when chooser is dismissed
  local originalCallback = chooser:completionCallback()
  chooser:completionCallback(function(choice)
    cmdNHotkey:delete()
    cmdPHotkey:delete()
    if originalCallback then
      originalCallback(choice)
    else
      if choice then
        choice.window:focus()
      else
        -- If user cancelled, re-enter the app modal
        if appModal then
          appModal:enter()
        end
      end
    end
  end)
end

function initModal()
  appModal = hs.hotkey.modal.new({ "cmd", "shift" }, "space")
  appModal:bind("", "escape", function()
    appModal:exit()
  end)
  appModal:bind("", "space", function()
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
