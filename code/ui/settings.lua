---@class SettingsMenu
local SettingsMenu = {}

function SettingsMenu:new()
  self._selected = 1
  self._settings = {
    {name = "Auto Complete", key = "autocomplete", type = "boolean"},
    {name = "Tab Width", key = "tabWidth", type = "number", min = 2, max = 8},
    {name = "Line Numbers", key = "lineNumbers", type = "boolean"},
    {name = "Update Mode", key = "updateMode", type = "select", 
     options = {"manual", "check", "auto"}},
  }
end

function SettingsMenu:render()
  local oldBg = term.getBackgroundColor()
  local oldFg = term.getTextColor()

  term.setBackgroundColor(colors.gray)
  term.clear()
  
  term.setCursorPos(1,1)
  term.setTextColor(colors.yellow)
  term.write("Settings")
  
  for i, setting in ipairs(self._settings) do
    term.setCursorPos(1, i+2)
    if i == self._selected then
      term.setBackgroundColor(colors.blue)
    else
      term.setBackgroundColor(colors.gray)
    end
    
    term.setTextColor(colors.white)
    local value = settings.get(setting.key)
    term.write(setting.name .. ": " .. tostring(value))
  end

  term.setBackgroundColor(oldBg)
  term.setTextColor(oldFg)
end

function SettingsMenu:handleKey(key)
  if key == keys.up then
    self._selected = math.max(1, self._selected - 1)
    return true
  elseif key == keys.down then
    self._selected = math.min(#self._settings, self._selected + 1) 
    return true
  elseif key == keys.enter then
    local setting = self._settings[self._selected]
    if setting.type == "boolean" then
      settings.set(setting.key, not settings.get(setting.key))
    elseif setting.type == "select" then
      local current = settings.get(setting.key)
      local idx = table.indexOf(setting.options, current) or 1
      idx = idx % #setting.options + 1
      settings.set(setting.key, setting.options[idx])
    end
    settings.save()
    return true
  end
end

---@type fun(): SettingsMenu  
local new = require "code.class" (SettingsMenu)
return new
