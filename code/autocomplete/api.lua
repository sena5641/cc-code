---@class ApiCompletion
local ApiCompletion = {}

---@class CompletionItem
---@field label string The text to display in completion list
---@field kind string The kind of completion (function, variable, etc)
---@field detail string? Additional details about the item
---@field documentation string? Documentation for the item

---@type table<string, CompletionItem[]>
local luaApis = {
  string = {
    { label = "byte", kind = "function", detail = "string.byte(s [, i [, j]])", documentation = "Returns the internal numeric codes of the characters s[i], s[i+1], ..., s[j]" },
    { label = "char", kind = "function", detail = "string.char(...)", documentation = "Returns a string with length equal to the number of arguments, in which each character has the internal numeric code equal to its corresponding argument" },
    { label = "find", kind = "function", detail = "string.find(s, pattern [, init [, plain]])", documentation = "Looks for the first match of pattern in the string s" },
    { label = "format", kind = "function", detail = "string.format(formatstring, ...)", documentation = "Returns a formatted version of its variable number of arguments following the description given in its first argument" },
    { label = "gmatch", kind = "function", detail = "string.gmatch(s, pattern)", documentation = "Returns an iterator function that, each time it is called, returns the next captures from pattern over the string s" },
    { label = "gsub", kind = "function", detail = "string.gsub(s, pattern, repl [, n])", documentation = "Returns a copy of s in which all (or the first n, if given) occurrences of the pattern have been replaced" },
    { label = "len", kind = "function", detail = "string.len(s)", documentation = "Returns the length of the string" },
    { label = "lower", kind = "function", detail = "string.lower(s)", documentation = "Returns a copy of the string with all uppercase letters changed to lowercase" },
    { label = "match", kind = "function", detail = "string.match(s, pattern [, init])", documentation = "Looks for the first match of pattern in the string s" },
    { label = "rep", kind = "function", detail = "string.rep(s, n [, sep])", documentation = "Returns a string that is the concatenation of n copies of the string s separated by the string sep" },
    { label = "reverse", kind = "function", detail = "string.reverse(s)", documentation = "Returns a string that is the string s reversed" },
    { label = "sub", kind = "function", detail = "string.sub(s, i [, j])", documentation = "Returns the substring of s that starts at i and continues until j" },
    { label = "upper", kind = "function", detail = "string.upper(s)", documentation = "Returns a copy of the string with all lowercase letters changed to uppercase" }
  },
  table = {
    { label = "concat", kind = "function", detail = "table.concat(list [, sep [, i [, j]]])", documentation = "Returns list[i]..sep..list[i+1] ··· sep..list[j]" },
    { label = "insert", kind = "function", detail = "table.insert(list, [pos,] value)", documentation = "Inserts element value at position pos in list" },
    { label = "remove", kind = "function", detail = "table.remove(list [, pos])", documentation = "Removes from list the element at position pos" },
    { label = "sort", kind = "function", detail = "table.sort(list [, comp])", documentation = "Sorts list elements in a given order, in-place" },
    { label = "unpack", kind = "function", detail = "table.unpack(list [, i [, j]])", documentation = "Returns the elements from the given list" }
  },
  math = {
    { label = "abs", kind = "function", detail = "math.abs(x)", documentation = "Returns the absolute value of x" },
    { label = "ceil", kind = "function", detail = "math.ceil(x)", documentation = "Returns the smallest integer larger than or equal to x" },
    { label = "floor", kind = "function", detail = "math.floor(x)", documentation = "Returns the largest integer smaller than or equal to x" },
    { label = "max", kind = "function", detail = "math.max(x, ...)", documentation = "Returns the argument with the maximum value" },
    { label = "min", kind = "function", detail = "math.min(x, ...)", documentation = "Returns the argument with the minimum value" },
    { label = "random", kind = "function", detail = "math.random([m [, n]])", documentation = "Returns a random real number between 0 and 1, or an integer between 1 and m, or between m and n" },
    { label = "randomseed", kind = "function", detail = "math.randomseed(x)", documentation = "Sets x as the seed for the pseudo-random generator" }
  }
}

---@type table<string, CompletionItem[]>
local ccApis = {
  fs = {
    { label = "open", kind = "function", detail = "fs.open(path, mode)", documentation = "Opens a file for reading or writing" },
    { label = "list", kind = "function", detail = "fs.list(path)", documentation = "Returns a list of files in the given directory" },
    { label = "exists", kind = "function", detail = "fs.exists(path)", documentation = "Checks if the given path exists" },
    { label = "isDir", kind = "function", detail = "fs.isDir(path)", documentation = "Checks if the given path is a directory" },
    { label = "makeDir", kind = "function", detail = "fs.makeDir(path)", documentation = "Creates a directory at the given path" },
    { label = "delete", kind = "function", detail = "fs.delete(path)", documentation = "Deletes a file or directory" },
    { label = "combine", kind = "function", detail = "fs.combine(path1, path2)", documentation = "Combines two path components" }
  },
  term = {
    { label = "clear", kind = "function", detail = "term.clear()", documentation = "Clears the terminal" },
    { label = "clearLine", kind = "function", detail = "term.clearLine()", documentation = "Clears the current line" },
    { label = "getCursorPos", kind = "function", detail = "term.getCursorPos()", documentation = "Returns the current cursor position" },
    { label = "setCursorPos", kind = "function", detail = "term.setCursorPos(x, y)", documentation = "Sets the cursor position" },
    { label = "write", kind = "function", detail = "term.write(text)", documentation = "Writes text at the current cursor position" },
    { label = "blit", kind = "function", detail = "term.blit(text, textColors, backgroundColors)", documentation = "Writes text with colors at the current cursor position" }
  },
  peripheral = {
    { label = "getType", kind = "function", detail = "peripheral.getType(side)", documentation = "Returns the type of peripheral attached to the given side" },
    { label = "isPresent", kind = "function", detail = "peripheral.isPresent(side)", documentation = "Checks if a peripheral is attached to the given side" },
    { label = "getMethods", kind = "function", detail = "peripheral.getMethods(side)", documentation = "Returns a list of methods available on the peripheral" },
    { label = "call", kind = "function", detail = "peripheral.call(side, method, ...)", documentation = "Calls a method on a peripheral" },
    { label = "wrap", kind = "function", detail = "peripheral.wrap(side)", documentation = "Returns a table containing all methods of the peripheral" }
  }
}

function ApiCompletion:new()
  self._apis = {
    lua = luaApis,
    cc = ccApis
  }
end

---Gets completion items for the given context
---@param line string The current line content
---@param pos integer The cursor position in the line
---@return CompletionItem[]
function ApiCompletion:getCompletions(line, pos)
  local prefix = line:sub(1, pos)
  local dotMatch = prefix:match("([%w_]+)%.$")
  
  if dotMatch then
    -- API object completion (e.g. "string.")
    local items = self._apis.lua[dotMatch] or self._apis.cc[dotMatch]
    return items or {}
  end
  
  -- Global API completion
  local items = {}
  for api, _ in pairs(self._apis.lua) do
    table.insert(items, {
      label = api,
      kind = "namespace",
      detail = api .. " (Lua API)",
      documentation = "Lua " .. api .. " standard library"
    })
  end
  for api, _ in pairs(self._apis.cc) do
    table.insert(items, {
      label = api,
      kind = "namespace", 
      detail = api .. " (CC API)",
      documentation = "ComputerCraft " .. api .. " API"
    })
  end
  return items
end

---@type fun(): ApiCompletion
local new = require "code.class" (ApiCompletion)
return new
