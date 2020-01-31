local ffi = require("ffi")

local reference = {}

local function cdata2rawptr(cdata)
	return tonumber(ffi.cast("uintptr_t",ffi.cast("void *", cdata)))
end

local function malloc(type)
	local cdata = ffi.new(type)
	local rawptr = cdata2rawptr(cdata)
	reference[rawptr] = {}
	
	return cdata
end

local function _setReference(t, k, v)
	local rawptr = cdata2rawptr(t)
	reference[rawptr][k] = v
	t[k] = v
end

local function setString(t, k, str)
	local chararray = ffi.new("char[?]", string.len(str) + 1)
	ffi.copy(chararray, str)
	_setReference(t, k, chararray)
end

local function setReference(t, k, v)
	if type(v) == "string" then
		return setString(t, k, v)
	else
		return _setReference(t, k, v)
	end
end

local function setCallback(t, callback_type, k, cb)
	local fficb = ffi.cast(callback_type, cb)
	return _setReference(t, k, fficb)
end

local function free(t)
	local rawptr = cdata2rawptr(t)
	reference[rawptr] = nil
end

return 
{
	malloc = malloc,
	setReference = setReference,
	setString = setString,
	setCallback = setCallback,
	free = free,
}