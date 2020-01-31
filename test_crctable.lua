local crc = require("crctable")
require("struct_define")
local ffi = require("ffi")

local M_gc_free = { __gc = function(t) print("gc") 
		crc.free(t) 
		end }

ffi.metatype("struct A", M_gc_free)
ffi.metatype("struct B", M_gc_free)
ffi.metatype("struct C", M_gc_free)

local function createC()
	local a = crc.malloc("struct A")
	crc.setString(a, "name", "a name")
	local f = function() print("call back") end
	crc.setCallback(a, "CB", "cb", f)
	a.ok = true
	
	local b = crc.malloc("struct B")
	crc.setReference(b, "a", a)
	b.id = 654
	
	local c = crc.malloc("struct C")
	crc.setReference(c, "b", b)
	crc.setReference(c, "name", "c name")
	c.id = 987
	
	return c
end

local c = createC()

collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")

print(c)
print(ffi.string(c.name))
print(c.id)
print(c.b)
print(c.b.id)
print(c.b.a)
print(ffi.string(c.b.a.name))
print(c.b.a.ok)
c.b.a.cb()

print("--------------------------")

c = nil

collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")
collectgarbage("collect")


print("--------------------------")