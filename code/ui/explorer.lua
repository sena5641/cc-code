---@class FileExplorer
local FileExplorer = {}

function FileExplorer:new()
  self._currentPath = "/"
  self._selected = 1
  self._offset = 0
end

function FileExplorer:render()
  local oldBg = term.getBackgroundColor()
  local oldFg = term.getTextColor()
  
  local w, h = term.getSize()
  
  -- Draw frame
  term.setBackgroundColor(colors.gray)
  term.clear()
  
  -- Draw path
  term.setCursorPos(1, 1)
  term.setTextColor(colors.yellow)
  term.write(self._currentPath)
  
  -- Get file list
  local files = fs.list(self._currentPath)
  table.sort(files)
  
  -- Draw files
  for i = 1, h-2 do
    local idx = i + self._offset
    local file = files[idx]
    if not file then break end
    
    term.setCursorPos(1, i+1)
    if i + self._offset == self._selected then
      term.setBackgroundColor(colors.blue)
    else
      term.setBackgroundColor(colors.gray) 
    end
    
    if fs.isDir(fs.combine(self._currentPath, file)) then
      term.setTextColor(colors.lightBlue)
      term.write("[" .. file .. "]")
    else
      term.setTextColor(colors.white)
      term.write(file)
    end
  end
  
  term.setBackgroundColor(oldBg)
  term.setTextColor(oldFg)
end

function FileExplorer:handleKey(key)
  if key == keys.up then
    self._selected = math.max(1, self._selected - 1)
    return true
  elseif key == keys.down then
    self._selected = self._selected + 1
    return true
  elseif key == keys.enter then
    local files = fs.list(self._currentPath)
    table.sort(files)
    local selected = files[self._selected]
    if selected then
      local path = fs.combine(self._currentPath, selected)
      if fs.isDir(path) then
        self._currentPath = path
        self._selected = 1
        self._offset = 0
      else
        return path
      end
    end
    return true
  elseif key == keys.backspace then
    if self._currentPath ~= "/" then
      self._currentPath = fs.getDir(self._currentPath)
      self._selected = 1
      self._offset = 0
    end
    return true
  end
end

---@type fun(): FileExplorer
local new = require "code.class" (FileExplorer)
return new
