local Editor = require "code.Editor"

local CONFIG_FILE = "/.code"
local VERSION_FILE = "/code/version"
local LATEST_COMMIT_URL = "https://api.github.com/repos/Possseidon/cc-code/commits/main"

local DEFAULT_CONFIG = {
  swapYZ = false,
  scrollAmount = 3,
  shortcuts = {},
  toastDuration = 3,
  ---@type UpdateMode
  update = "auto",
}

---@alias UpdateMode
---| "manual" Does not check for updates at all.
---| "check"  Pushes a toast if an update is available.
---| "auto"   Pushes a toast and automatically updates on close.

---@alias Action fun()

---@alias ToastKind
---|>"success"
---| "warning"
---| "error"

---@class Toast
---@field message string
---@field kind ToastKind
---@field timer integer

---Maps event names to event handlers.
---@type table<string, fun(code: Code, ...): boolean?>
local on = {}

---A char was typed and gets inserted at the current cursor position.
---@param code Code
---@param char string
function on.char(code, char)
  if char == "." then
    code._editor:insert(char)
    code._editor:showCompletion()
  else
    code._editor:insert(char)
    if code._editor._completionVisible then
      code._editor:updateCompletion()
    end
  end
  return true
end

---A key was pressed, triggering corresponding shortcut actions and updating internal modifier key state.
---@param code Code
---@param key integer
---@param _held boolean
function on.key(code, key, _held)
  if code._editor._completionVisible then
    if key == keys.up then
      code._editor._completionSelected = math.max(1, code._editor._completionSelected - 1)
      return true
    elseif key == keys.down then
      code._editor._completionSelected = math.min(#code._editor._completionItems, code._editor._completionSelected + 1)
      return true
    elseif key == keys.enter or key == keys.tab then
      local selected = code._editor._completionItems[code._editor._completionSelected]
      if selected then
        code._editor:insert(selected.label)
        code._editor._completionVisible = false
      end
      return true
    elseif key == keys.escape then
      code._editor._completionVisible = false
      return true
    end
  end

  if key == keys.leftCtrl or key == keys.rightCtrl then
    code._modifierKeys.ctrl = true
  elseif key == keys.leftShift or key == keys.rightShift then
    code._modifierKeys.shift = true
  elseif key == keys.leftAlt or key == keys.rightAlt then
    code._modifierKeys.alt = true
  else
    if code._config.swapYZ then
      if key == keys.z then
        key = keys.y
      elseif key == keys.y then
        key = keys.z
      end
    end

    local keyName = keys.getName(key)
    if not keyName then
      return
    end

    local ctrl = code._modifierKeys.ctrl and "ctrl+" or ""
    local shift = code._modifierKeys.shift and "shift+" or ""
    local alt = code._modifierKeys.alt and "alt+" or ""
    local action = code._shortcuts[ctrl .. shift .. alt .. keyName]
    if action then
      local ok, err = pcall(action, code)
      if not ok then
        code:pushToast(err, "error")
      end
      return true
    end
  end
end

---A key was released, updating internal modifier key state.
---@param code Code
---@param key integer
function on.key_up(code, key)
  if key == keys.leftCtrl or key == keys.rightCtrl then
    code._modifierKeys.ctrl = false
  elseif key == keys.leftShift or key == keys.rightShift then
    code._modifierKeys.shift = false
  elseif key == keys.leftAlt or key == keys.rightAlt then
    code._modifierKeys.alt = false
  end
end

---The term was resized, requiring a redraw.
---@param _code Code
function on.term_resize(_code)
  return true
end

---A mouse button was clicked, moving the cursor to that position.
---@param code Code
---@param _button integer
---@param x integer
---@param y integer
function on.mouse_click(code, _button, x, y)
  code._editor:click(x, y)
  return true
end

---The mouse is being dragged for selecting text.
---@param code Code
---@param _button integer
---@param x integer
---@param y integer
function on.mouse_drag(code, _button, x, y)
  code._editor:drag(x, y)
  return true
end

---Scrolls the editor.
---@param code Code
---@param direction integer
---@param _x integer
---@param _y integer
function on.mouse_scroll(code, direction, _x, _y)
  code._editor:scrollBy(0, direction * code._config.scrollAmount)
  return true
end

---A mouse button was released.
---@param code Code
---@param _button integer
---@param _x integer
---@param _y integer
function on.mouse_up(code, _button, _x, _y)
  code._editor:release()
end

---Pastes text from the internal clipboard (or from the real clipboard if shift was held down).
---@param code Code
---@param text string
function on.paste(code, text)
  if code._modifierKeys.shift then
    code._editor:insert(text)
  else
    code._editor:paste()
  end
  return true
end

---A timer was fired.
---@param code Code
---@param timer integer
function on.timer(code, timer)
  local toastDeleted = false

  for i, toast in ipairs(code._toasts) do
    if toast.timer == timer then
      table.remove(code._toasts, i)
      toastDeleted = true
      break
    end
  end

  return toastDeleted
end

---A http request was successful.
---@param code Code
---@param url string
---@param response table
function on.http_success(code, url, response)
  if url == LATEST_COMMIT_URL then
    local main = textutils.unserializeJSON(response.readAll())
    if not main or not main.sha then
      code:pushToast("Update-Check Failed:", "error")
      code:pushToast("Could not parse GitHub API response as JSON", "error")
      return true
    end

    if main.sha == code._installedVersion.sha then return end

    code:pushToast("Update Available!")
    if code._config.update == "check" then
      code:pushToast("Run \"code --update\" to update")
    else
      code._updateOnClose = true
      code:pushToast("Close cc-code to update")
    end

    return true
  end
end

---A http request failed.
---@param code Code
---@param url string
---@param err string
---@param response table?
function on.http_failure(code, url, err, response)
  if url == LATEST_COMMIT_URL then
    code:pushToast("Update-Check Failed:", "error")
    code:pushToast(err, "error")
    if response then
      code:pushToast(response.readAll(), "error")
    end

    return true
  end
end

---@class Code
local Code = {}

function Code:new(filename)
  self._running = true
  self._filename = filename
  self._shortcuts = {}

  self._modifierKeys = {
    ctrl = false,
    shift = false,
    alt = false,
  }

  self._editor = Editor()

  self._config = nil
  self._invalidConfig = false

  ---@type Toast[]
  self._toasts = {}

  self._updateOnClose = false
  self._installedVersion = nil

  self:loadConfig()
  self:registerDefaultShortcuts()
  self:registerConfigShortcuts()
  self:open(filename)
  self:updateMultishell()
end

---Pushes a new toast with the given message.
---@param message string
---@param kind ToastKind?
function Code:pushToast(message, kind)
  table.insert(self._toasts, {
    message = message,
    kind = kind or "success",
    ---@diagnostic disable-next-line: undefined-field
    timer = os.startTimer(self._config.toastDuration),
  })
end

---Loads settings from the config file.
function Code:loadConfig()
  local config
  if fs.exists(CONFIG_FILE) then
    local file = fs.open(CONFIG_FILE, "rb")
    if file then
      local content = file.readAll()
      file.close()
      config = textutils.unserialize(content)
    end
    if not config then
      self._invalidConfig = true
      config = {}
    end
  else
    config = {}
  end
  self._config = setmetatable(config, { __index = DEFAULT_CONFIG })
  if self._invalidConfig then
    self:pushToast("Invalid Config - using default", "warning")
  end
end

---Saves settings to the config file.
function Code:saveConfig()
  if self._invalidConfig then return end
  local meta = getmetatable(self._config)
  setmetatable(self._config, nil)
  if next(self._config) == nil then
    fs.delete(CONFIG_FILE)
  else
    local content = textutils.serialize(self._config)
    local file, error = fs.open(CONFIG_FILE, "wb")
    if file then
      file.write(content)
      file.close()
    else
      self:pushToast(error, "error")
    end
  end
  setmetatable(self._config, meta)
end

---Opens the given file for editing.
---@param filename string
function Code:open(filename)
  if fs.exists(filename) then
    local file, error = fs.open(filename, "rb")
    if file then
      local content = file.readAll() or ""
      file.close()
      self._editor:setContent(content)
      self._editor:markSaved()
      self:pushToast(filename .. ": Opened")
    else
      self:pushToast(error, "error")
    end
  else
    self:pushToast(filename .. ": New File - not saved yet", "warning")
  end
end

---Updates the multishell title to the current filename, possibly with an `*` indicating modifications.
function Code:updateMultishell()
  if multishell then
    local title = fs.getName(self._filename)
    if not self._editor:saved() then
      title = title .. "*"
    end
    multishell.setTitle(multishell.getCurrent(), title)
  end
end

---Registers all default shortcuts for general purpose editing.
function Code:registerDefaultShortcuts()
  self:registerScript("shift?+left", "editor:cursorLeft(shift)")
  self:registerScript("ctrl+shift?+left", "editor:cursorWordLeft(shift)")

  self:registerScript("shift?+right", "editor:cursorRight(shift)")
  self:registerScript("ctrl+shift?+right", "editor:cursorWordRight(shift)")

  self:registerScript("alt+up", "editor:swapLinesUp()")
  self:registerScript("shift?+up", "editor:moveCursor(0, -1, shift)")
  self:registerScript("ctrl+up", "editor:scrollBy(0, -1)")

  self:registerScript("alt+down", "editor:swapLinesDown()")
  self:registerScript("shift?+down", "editor:moveCursor(0, 1, shift)")
  self:registerScript("ctrl+down", "editor:scrollBy(0, 1)")

  self:registerScript("shift?+tab", "editor:tab(shift)")
  self:registerScript("shift?+enter", "editor:enter(shift)")

  self:registerScript("backspace", "editor:backspace()")
  self:registerScript("ctrl+backspace", "editor:backspaceWord()")

  self:registerScript("delete", "editor:delete()")
  self:registerScript("ctrl+delete", "editor:deleteWord()")
  self:registerScript("shift+delete", "editor:deleteLine()")

  self:registerScript("shift?+home", "editor:cursorLineHome(shift)")
  self:registerScript("ctrl+shift?+home", "editor:cursorDocumentHome(shift)")

  self:registerScript("shift?+end", "editor:cursorLineEnd(shift)")
  self:registerScript("ctrl+shift?+end", "editor:cursorDocumentEnd(shift)")

  self:registerScript("alt+pageUp", "editor:scrollPageUp()")
  self:registerScript("shift?+pageUp", "editor:cursorPageUp(shift)")

  self:registerScript("alt+pageDown", "editor:scrollPageDown()")
  self:registerScript("shift?+pageDown", "editor:cursorPageDown(shift)")

  self:registerScript("ctrl+a", "editor:selectAll()")

  self:registerScript("ctrl+z", "editor:undo()")
  self:registerScript("ctrl+shift+z", "editor:redo()")
  self:registerScript("ctrl+y", "editor:redo()")

  self:registerScript("ctrl+x", "editor:cut()")
  self:registerScript("ctrl+c", "editor:copy()")
  -- Only triggers a paste event and is hardcoded there.
  -- self:registerScript("ctrl+v", "editor:paste()")

  self:registerScript("ctrl+s", "code:save()")
  self:registerScript("ctrl+d", "code:save()")
  self:registerScript("ctrl+shift?+f4", "code:quit(shift)")
  self:registerScript("f5", "code:runFile()")
  -- Добавляем новые горячие клавиши:
  self:registerScript("f8", "editor:toggleCompletion()")
  self:registerScript("f12", "code:showHelp()")
end

function Code:runFile()
  self:save()
  if multishell then
    shell.run("fg", self._filename)
  else
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    shell.run(self._filename)
  end
end

---Отображает справочное меню
function Code:showHelp()
  local oldTextColor = term.getTextColor()
  local oldBgColor = term.getBackgroundColor()
  term.setBackgroundColor(colors.gray)
  term.clear()
  term.setCursorPos(1,1)
  term.setTextColor(colors.white)
  print("=== Справка по cc-code ===")
  print("")
  print("F8  - Вкл/Выкл автодополнение")
  print("F12 - Справка")
  print("--settings - Открыть меню с настройками")
  print("--update   - Обновить cc-code")
  print("--version  - Показать версию")
  print("ctrl+D   - Сохранить файл")
  print("ctrl+S   - Выключить компьютер (у ComputerCraft)")
  print("")
  print("Нажмите любую клавишу для возврата...")
  os.pullEvent("key")
  term.setBackgroundColor(oldBgColor)
  term.setTextColor(oldTextColor)
  term.clear()
  self:render()
end

---Отображает текущее меню настроек
function Code:showSettings()
  local oldTextColor = term.getTextColor()
  local oldBgColor = term.getBackgroundColor()
  term.setBackgroundColor(colors.blue)
  term.clear()
  term.setCursorPos(1,1)
  term.setTextColor(colors.white)
  print("=== Настройки cc-code ===")
  print("")
  for k,v in pairs(self._config) do
    print(k .. " = " .. tostring(v))
  end
  print("")
  print("Для изменения настроек отредактируйте файл '/.code'")
  print("Нажмите любую клавишу для возврата...")
  os.pullEvent("key")
  term.setBackgroundColor(oldBgColor)
  term.setTextColor(oldTextColor)
  term.clear()
  self:render()
end

---Switches to the next (or previous) multishell tab.
---@param back boolean?
function Code:switchTab(back)
  if multishell then
    local current = multishell.getCurrent()
    if current ~= multishell.getFocus() then return end
    multishell.setFocus((back and current - 2 or current) % multishell.getCount() + 1)
  end
end

---Registers shortcuts from the currently loaded config.
function Code:registerConfigShortcuts()
  for combo, script in pairs(self._config.shortcuts) do
    self:registerScript(combo, script)
  end
end

---Creates a new action from the given script containing Lua code.
---
---The script has a few globals set:
--- - `code` for access to this current class
--- - `editor` as shorthand for `code._editor`
--- - `ctrl`, `shift` and `alt` to get modifier keys (as boolean)
---
---@param script string
---@return Action
function Code:createAction(script)
  local env = _ENV
  return assert(load(script, nil, nil, setmetatable({
    code = self,
    editor = self._editor,
  }, {
    __index = function(action, key)
      if key == "ctrl" then
        return action.code._modifierKeys.ctrl
      elseif key == "shift" then
        return action.code._modifierKeys.shift
      elseif key == "alt" then
        return action.code._modifierKeys.alt
      else
        return env[key]
      end
    end,
  })))
end

---Registers an action with a key combination.
---
---The combo has the format `ctrl?+shift+s` which allows using `ctrl` as a boolean in the action.
---
---@param combo string
---@param action Action
function Code:registerAction(combo, action)
  local optional = combo:match("(%w+)%?%+")
  if optional then
    self:registerAction(combo:gsub(optional .. "%?%+", ""), action)
    self:registerAction(combo:gsub(optional .. "%?", optional), action)
  else
    self._shortcuts[combo] = action
  end
end

---Registers a Lua script to the given key combination.
---
---This is just a shorthand for calling both createAction and registerAction.
---
---@param combo string
---@param script string
function Code:registerScript(combo, script)
  self:registerAction(combo, self:createAction(script))
end

---Exits, asking for confirmation on unsaved changes (unless `force` is set to true).
---@param force boolean?
function Code:quit(force)
  if force or self._editor:saved() then
    self._running = false
  else
    self:pushToast(self._filename .. ": Unsaved Changes", "error")
  end
end

---Saves the current state to disk and also marks the current state as "saved" internally.
function Code:save()
  local content = self._editor:getContent()
  local file, error = fs.open(self._filename, "wb")
  if file then
    file.write(content)
    file.close()
    self._editor:markSaved()
    self:pushToast(self._filename .. ": Saved")
  else
    self:pushToast(error, "error")
  end
end

---Forwards an event with all its parameters to the `on` table of event handlers.
---
---Ignores events that aren't in the `on` table.
---
---@param event string
---@param ... any
---@return boolean?
function Code:processEvent(event, ...)
  local handler = on[event]
  if handler then
    return handler(self, ...)
  end
end

---Renders the entire code editor and updates the cursor.
function Code:render()
  term.setCursorBlink(false)
  self._editor:render()
  self:renderToasts()
  self._editor:updateCursor()
end

local toastColors = {
  success = colors.green,
  warning = colors.blue,
  error = colors.red,
}

---Renders toasts in the bottom right corner of the screen.
function Code:renderToasts()
  local width, height = term.getSize()
  for i, toast in ipairs(self._toasts) do
    term.setBackgroundColor(colors.white)
    term.setTextColor(toastColors[toast.kind])
    local message = " " .. toast.message .. " "
    term.setCursorPos(width - #message + 1, height - #self._toasts + i)
    term.write(message)
  end
end

---@class Version
---@field sha string The commit hash of the intalled version.
---@field lastCheck integer The timestamp of the last update-check.

---Reads the currently installed version information from disk.
---@return Version?
local function getInstalledVersion()
  local f = fs.open(VERSION_FILE, "r")
  if not f then return nil end
  local version = f.readAll()
  f.close()
  return textutils.unserialize(version)
end

---Sends an update request if the config requires it and the current version is known.
function Code:sendUpdateCheckRequest()
  if self._config.update == "manual" then return end

  self._installedVersion = getInstalledVersion()
  if not self._installedVersion then return end

  ---@diagnostic disable-next-line: undefined-field
  local now = os.epoch("utc")
  if now < self._installedVersion.lastCheck + 60000 then return end
  self._installedVersion.lastCheck = now

  local version = textutils.serialize(self._installedVersion)
  local f = fs.open(VERSION_FILE, "w")
  if not f then return end
  f.write(version)
  f.close()

  self:pushToast("Checking for updates...")

  http.request(LATEST_COMMIT_URL)
end

---Runs the application until the user exits.
function Code:run()
  self:sendUpdateCheckRequest()

  self:render()
  while self._running do
    ---@diagnostic disable-next-line: undefined-field
    if self:processEvent(os.pullEvent()) then
      self:render()
      self:updateMultishell()
    end
  end
  if fs.combine(self._filename) ~= CONFIG_FILE then
    self:saveConfig()
  end
end

---@type fun(filename: string): Code
local new = require "code.class" (Code)
return new
