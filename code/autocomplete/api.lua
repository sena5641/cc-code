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
    { label = "unpack", kind = "function", detail = "table.unpack(list [, i [, j]])", documentation = "Returns the elements from the given list" },
    { label = "move", kind = "function", detail = "table.move(a1, f, e, t [,a2])", documentation = "Moves elements from table a1 to table a2" },
    { label = "pack", kind = "function", detail = "table.pack(...)", documentation = "Returns a new table with all parameters stored into keys 1, 2, etc. and with a field \"n\" with the total number of parameters" }
  },
  math = {
    { label = "abs", kind = "function", detail = "math.abs(x)", documentation = "Returns the absolute value of x" },
    { label = "ceil", kind = "function", detail = "math.ceil(x)", documentation = "Returns the smallest integer larger than or equal to x" },
    { label = "floor", kind = "function", detail = "math.floor(x)", documentation = "Returns the largest integer smaller than or equal to x" },
    { label = "max", kind = "function", detail = "math.max(x, ...)", documentation = "Returns the argument with the maximum value" },
    { label = "min", kind = "function", detail = "math.min(x, ...)", documentation = "Returns the argument with the minimum value" },
    { label = "random", kind = "function", detail = "math.random([m [, n]])", documentation = "Returns a random real number between 0 and 1, or an integer between 1 and m, or between m and n" },
    { label = "randomseed", kind = "function", detail = "math.randomseed(x)", documentation = "Sets x as the seed for the pseudo-random generator" },
    { label = "deg", kind = "function", detail = "math.deg(x)", documentation = "Converts angle x from radians to degrees" },
    { label = "rad", kind = "function", detail = "math.rad(x)", documentation = "Converts angle x from degrees to radians" },
    { label = "fmod", kind = "function", detail = "math.fmod(x, y)", documentation = "Returns the remainder of x divided by y that rounds the quotient towards zero" },
    { label = "modf", kind = "function", detail = "math.modf(x)", documentation = "Returns the integral part of x and the fractional part of x" },
    { label = "huge", kind = "variable", detail = "math.huge", documentation = "A value larger than any other numeric value" },
    { label = "pi", kind = "variable", detail = "math.pi", documentation = "The value of π" }
  },
  os = {
    { label = "clock", kind = "function", detail = "os.clock()", documentation = "Returns an approximation of the amount in seconds of CPU time used by the program" },
    { label = "date", kind = "function", detail = "os.date([format [, time]])", documentation = "Returns a string or a table containing date and time" },
    { label = "time", kind = "function", detail = "os.time([table])", documentation = "Returns the current time when called without arguments, or a time specified by the given table" },
    { label = "epoch", kind = "function", detail = "os.epoch([format])", documentation = "Returns the current epoch time in the specified format" },
    { label = "startTimer", kind = "function", detail = "os.startTimer(timeout)", documentation = "Starts a timer that will run after the specified number of seconds" },
    { label = "sleep", kind = "function", detail = "os.sleep(timeout)", documentation = "Pauses execution for the specified number of seconds" },
    { label = "exit", kind = "function", detail = "os.exit()", documentation = "Terminates the program" }
  },
  coroutine = {
    { label = "create", kind = "function", detail = "coroutine.create(f)", documentation = "Creates a new coroutine" },
    { label = "resume", kind = "function", detail = "coroutine.resume(co, ...)", documentation = "Resumes a suspended coroutine" },
    { label = "yield", kind = "function", detail = "coroutine.yield(...)", documentation = "Suspends the execution of the calling coroutine" },
    { label = "status", kind = "function", detail = "coroutine.status(co)", documentation = "Returns the status of the coroutine" },
    { label = "wrap", kind = "function", detail = "coroutine.wrap(f)", documentation = "Creates a coroutine and returns a function that resumes it" },
    { label = "running", kind = "function", detail = "coroutine.running()", documentation = "Returns the running coroutine and a boolean indicating if it is the main coroutine" }
  },
  debug = {
    { label = "traceback", kind = "function", detail = "debug.traceback([thread,] [message [, level]])", documentation = "Returns a string with a traceback of the call stack" },
    { label = "getinfo", kind = "function", detail = "debug.getinfo([thread,] f [, what])", documentation = "Returns a table with information about a function" },
    { label = "getlocal", kind = "function", detail = "debug.getlocal([thread,] f, local)", documentation = "Returns the name and value of a local variable" },
    { label = "setlocal", kind = "function", detail = "debug.setlocal([thread,] f, local, value)", documentation = "Assigns a value to a local variable" },
    { label = "getupvalue", kind = "function", detail = "debug.getupvalue(f, up)", documentation = "Returns the name and value of an upvalue" },
    { label = "setupvalue", kind = "function", detail = "debug.setupvalue(f, up, value)", documentation = "Assigns a value to an upvalue" }
  },
  io = {
    { label = "open", kind = "function", detail = "io.open(filename [, mode])", documentation = "Opens a file in the specified mode" },
    { label = "close", kind = "function", detail = "io.close([file])", documentation = "Closes a file" },
    { label = "read", kind = "function", detail = "io.read(...)", documentation = "Reads from the standard input" },
    { label = "write", kind = "function", detail = "io.write(...)", documentation = "Writes to the standard output" },
    { label = "flush", kind = "function", detail = "io.flush()", documentation = "Flushes the output buffer" },
    { label = "lines", kind = "function", detail = "io.lines([filename])", documentation = "Returns an iterator for reading lines from a file" }
  },
  package = {
    { label = "loadlib", kind = "function", detail = "package.loadlib(libname, funcname)", documentation = "Loads a C library" },
    { label = "searchpath", kind = "function", detail = "package.searchpath(name, path [, sep [, rep]])", documentation = "Searches for a module" },
    { label = "loaded", kind = "variable", detail = "package.loaded", documentation = "A table of loaded modules" },
    { label = "path", kind = "variable", detail = "package.path", documentation = "The path used by require to search for Lua files" },
    { label = "cpath", kind = "variable", detail = "package.cpath", documentation = "The path used by require to search for C libraries" }
  },
  keywords = {
    { label = "and", kind = "keyword", detail = "Lua keyword", documentation = "Logical AND operator" },
    { label = "break", kind = "keyword", detail = "Lua keyword", documentation = "Breaks out of a loop" },
    { label = "do", kind = "keyword", detail = "Lua keyword", documentation = "Starts a block of code" },
    { label = "else", kind = "keyword", detail = "Lua keyword", documentation = "Specifies the else branch of an if statement" },
    { label = "elseif", kind = "keyword", detail = "Lua keyword", documentation = "Specifies an additional condition in an if statement" },
    { label = "end", kind = "keyword", detail = "Lua keyword", documentation = "Ends a block of code" },
    { label = "false", kind = "keyword", detail = "Lua keyword", documentation = "Boolean false value" },
    { label = "for", kind = "keyword", detail = "Lua keyword", documentation = "Starts a for loop" },
    { label = "function", kind = "keyword", detail = "Lua keyword", documentation = "Defines a function" },
    { label = "if", kind = "keyword", detail = "Lua keyword", documentation = "Starts an if statement" },
    { label = "in", kind = "keyword", detail = "Lua keyword", documentation = "Used in for loops" },
    { label = "local", kind = "keyword", detail = "Lua keyword", documentation = "Declares a local variable" },
    { label = "nil", kind = "keyword", detail = "Lua keyword", documentation = "Represents a nil value" },
    { label = "not", kind = "keyword", detail = "Lua keyword", documentation = "Logical NOT operator" },
    { label = "or", kind = "keyword", detail = "Lua keyword", documentation = "Logical OR operator" },
    { label = "repeat", kind = "keyword", detail = "Lua keyword", documentation = "Starts a repeat-until loop" },
    { label = "return", kind = "keyword", detail = "Lua keyword", documentation = "Returns from a function" },
    { label = "then", kind = "keyword", detail = "Lua keyword", documentation = "Specifies the then branch of an if statement" },
    { label = "true", kind = "keyword", detail = "Lua keyword", documentation = "Boolean true value" },
    { label = "until", kind = "keyword", detail = "Lua keyword", documentation = "Ends a repeat-until loop" },
    { label = "while", kind = "keyword", detail = "Lua keyword", documentation = "Starts a while loop" }
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
  },
  redstone = {
    { label = "getInput", kind = "function", detail = "redstone.getInput(side)", documentation = "Gets the redstone input from the specified side" },
    { label = "setOutput", kind = "function", detail = "redstone.setOutput(side, boolean)", documentation = "Sets the redstone output for the specified side" },
    { label = "getAnalogInput", kind = "function", detail = "redstone.getAnalogInput(side)", documentation = "Gets the analog redstone input from the specified side" },
    { label = "setAnalogOutput", kind = "function", detail = "redstone.setAnalogOutput(side, value)", documentation = "Sets the analog redstone output for the specified side" }
  },
  colors = {
    { label = "white", kind = "variable", detail = "colors.white", documentation = "The color white (0x1)" },
    { label = "orange", kind = "variable", detail = "colors.orange", documentation = "The color orange (0x2)" },
    { label = "magenta", kind = "variable", detail = "colors.magenta", documentation = "The color magenta (0x4)" },
    { label = "lightBlue", kind = "variable", detail = "colors.lightBlue", documentation = "The color light blue (0x8)" },
    { label = "yellow", kind = "variable", detail = "colors.yellow", documentation = "The color yellow (0x10)" },
    { label = "lime", kind = "variable", detail = "colors.lime", documentation = "The color lime (0x20)" },
    { label = "pink", kind = "variable", detail = "colors.pink", documentation = "The color pink (0x40)" },
    { label = "gray", kind = "variable", detail = "colors.gray", documentation = "The color gray (0x80)" },
    { label = "lightGray", kind = "variable", detail = "colors.lightGray", documentation = "The color light gray (0x100)" },
    { label = "cyan", kind = "variable", detail = "colors.cyan", documentation = "The color cyan (0x200)" },
    { label = "purple", kind = "variable", detail = "colors.purple", documentation = "The color purple (0x400)" },
    { label = "blue", kind = "variable", detail = "colors.blue", documentation = "The color blue (0x800)" },
    { label = "brown", kind = "variable", detail = "colors.brown", documentation = "The color brown (0x1000)" },
    { label = "green", kind = "variable", detail = "colors.green", documentation = "The color green (0x2000)" },
    { label = "red", kind = "variable", detail = "colors.red", documentation = "The color red (0x4000)" },
    { label = "black", kind = "variable", detail = "colors.black", documentation = "The color black (0x8000)" },
    { label = "combine", kind = "function", detail = "colors.combine(...)", documentation = "Combines a set of colors into a single color" },
    { label = "subtract", kind = "function", detail = "colors.subtract(colors, ...)", documentation = "Removes a set of colors from an initial color" },
    { label = "test", kind = "function", detail = "colors.test(colors, color)", documentation = "Tests whether a color contains another color" },
    { label = "toBlit", kind = "function", detail = "colors.toBlit(color)", documentation = "Converts a color to its blit character" }
  },
  http = {
    { label = "request", kind = "function", detail = "http.request(url [, body [, headers [, binary]]])", documentation = "Makes a HTTP request to the specified URL" },
    { label = "get", kind = "function", detail = "http.get(url [, headers [, binary]])", documentation = "Makes a HTTP GET request to the specified URL" },
    { label = "post", kind = "function", detail = "http.post(url, body [, headers [, binary]])", documentation = "Makes a HTTP POST request to the specified URL" },
    { label = "checkURL", kind = "function", detail = "http.checkURL(url)", documentation = "Checks if a URL is allowed to be requested" }
  },
  turtle = {
    { label = "forward", kind = "function", detail = "turtle.forward()", documentation = "Moves the turtle forward" },
    { label = "back", kind = "function", detail = "turtle.back()", documentation = "Moves the turtle backward" },
    { label = "up", kind = "function", detail = "turtle.up()", documentation = "Moves the turtle up" },
    { label = "down", kind = "function", detail = "turtle.down()", documentation = "Moves the turtle down" },
    { label = "turnLeft", kind = "function", detail = "turtle.turnLeft()", documentation = "Turns the turtle to the left" },
    { label = "turnRight", kind = "function", detail = "turtle.turnRight()", documentation = "Turns the turtle to the right" },
    { label = "dig", kind = "function", detail = "turtle.dig()", documentation = "Digs the block in front of the turtle" },
    { label = "place", kind = "function", detail = "turtle.place()", documentation = "Places a block in front of the turtle" },
    { label = "attack", kind = "function", detail = "turtle.attack()", documentation = "Attacks the entity in front of the turtle" },
    { label = "suck", kind = "function", detail = "turtle.suck()", documentation = "Sucks items from the inventory in front of the turtle" },
    { label = "drop", kind = "function", detail = "turtle.drop()", documentation = "Drops items from the turtle's inventory" }
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
  
  if (dotMatch) then
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
