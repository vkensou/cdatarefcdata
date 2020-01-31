local ffi = require("ffi")
ffi.cdef [[
typedef void(*CB)();
struct A { bool ok; const char* name; CB cb; };
struct B { int id; const char* name; struct A* a; };
struct C { int id; const char* name; struct B* b; };
]]
