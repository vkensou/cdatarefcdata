# cdatarefcdata
This module is work for cdata reference cdata in luajit ffi.

Here is a example:

```
ffi.cdef[[
    struct A { int id; };
    struct B { int id; struct A* a; };
]]

function createB()
    local a = ffi.new("struct A")
    local b = ffi.new("struct B")
    b.a = a
    return b
end
```

Above code won't work properly. Because in luajit ffi, you must reference a and b manually. 

So I made this library to automatically reference cdatas.
Here are 2 ways to do this: save all cdatas in one c array ([see here](https://github.com/LuaJIT/LuaJIT/issues/554#issuecomment-579318320_)), or save references in lua table.

## save in c array

```
local crc = require("crcarray")

function createB()
    local b = crc.start("struct B")
    crc.setValue(b, "int", "id", 987)
    local a = crc.malloc("struct A")
    crc.setReference(b, "a", a)
    crc.setValue(a, "int", "id", 654)
    return crc.complete()
end

local b, chunk = createB()
print(b.id)
print(b.a.id)
```
## save in lua table

```
local crc = require("crctable")

local M_gc_free = { __gc = function(t) print("gc") 
	crc.free(t) 
	end }

ffi.metatype("struct A", M_gc_free)
ffi.metatype("struct B", M_gc_free)

function createB()
    local a = crc.malloc("struct A")
    a.id = 654
    local b = crc.malloc("struct B")
    b.id = 987
    crc.setReference(b, "a", a)
    return b
end

b = createB()
print(b.id)
print(b.a.id)
```