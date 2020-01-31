local ffi = require("ffi")
ffi.cdef [[
typedef void(*CB3)();
struct A3 { CB3 cb; };
]]

local a = ffi.new("struct A3")
local luacb = function() print("call back") end
local fficb = ffi.cast("CB3", luacb)
a.cb = fficb


luacb = nil
fficb = nil

collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")


a.cb()      --I thought it would crash here