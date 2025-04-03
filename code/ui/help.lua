---@class HelpMenu
local HelpMenu = {}

function HelpMenu:new()
  self._helps = {
    {key = "F3", desc = "Settings menu"},
    {key = "F8", desc = "Toggle auto-completion"},
    {key = "F10", desc = "File explorer"},
    {key = "F12", desc = "Help"},
    {key = "Ctrl+D", desc = "Save file"},
    {key = "Ctrl+S", desc = "Shutdown computer (ComputerCraft)"},
    {key = "--update", desc = "Update cc-code"},
    {key = "--version", desc = "Show version"},
  }
end

function HelpMenu:render()
  local oldBg = term.getBackgroundColor() 
  local oldFg = term.getTextColor()

  term.setBackgroundColor(colors.gray)
  term.clear()
  
  term.setCursorPos(1,1)
  term.setTextColor(colors.yellow)
  term.write("CC-Code Help")

  for i, help in ipairs(self._helps) do
    term.setCursorPos(1, i+2)
    term.setTextColor(colors.white)
    term.write(help.key .. " - " .. help.desc)
  end

  term.setBackgroundColor(oldBg)
  term.setTextColor(oldFg)
end

---@type fun(): HelpMenu
local new = require "code.class" (HelpMenu)
return new
