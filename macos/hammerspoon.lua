local padding = 5

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
  -- hs.execute("kitty", true)
  hs.application.launchOrFocus("kitty.app")
  -- local kitty = hs.application.find("kitty")
  -- if not kitty then
  --   hs.execute("/Applications/kitty.app/Contents/MacOS/kitty", true)
  -- else
  --   hs.application.launchOrFocus("kitty.app")
  --   -- hs.alert.show("Kitty is already running")
  -- end
end)

function bindAppModal(modal, key, app)
  modal:bind("", key, function()
    pushWindowToRecent()
    hs.application.launchOrFocus(app)
    modal:exit()
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

  -- Debug: Show all running applications if VS Code not found
  if not vscodeApp then
    local runningApps = hs.application.runningApplications()
    local vscodeApps = {}
    for _, app in ipairs(runningApps) do
      local appName = app:name()
      if string.find(string.lower(appName), "code") or string.find(string.lower(appName), "visual") then
        table.insert(vscodeApps, appName)
      end
    end

    if #vscodeApps > 0 then
      hs.alert.show("Found code-related apps: " .. table.concat(vscodeApps, ", "))
      -- Try to use the first one found
      vscodeApp = hs.application.find(vscodeApps[1])
    else
      hs.alert.show("Visual Studio Code is not running")
      return
    end
  end

  if not vscodeApp then
    hs.alert.show("Could not find VS Code application")
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
    hs.alert.show("No visible VS Code windows found")
    return
  end

  if #visibleWindows == 1 then
    visibleWindows[1]:focus()
    return
  end

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
  local cmdNHotkey = hs.hotkey.bind({"cmd"}, "n", function()
    local currentRow = chooser:selectedRow()
    local nextRow = (currentRow % #choices) + 1
    chooser:selectedRow(nextRow)
  end)
  
  local cmdPHotkey = hs.hotkey.bind({"cmd"}, "p", function()
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
      end
    end
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

-- VS Code window chooser
hs.hotkey.bind({ "cmd", "shift" }, "v", function()
  showVSCodeWindowChooser()
end)

initModal()

hs.alert.show("Config loaded")
