local ffi = require("ffi")

local totalLength = 0
local _align = 4
local targettype
local command = {}
local commandNum = 0
local stringbuffer = {}
local callbacks = {}
local started = false

local OFFSET = 1
local TYPE = 2
local FAKESELF = 3

local function alignedSize(size)
	return math.ceil(size / _align) * _align
end

local function cdata2rawptr(cdata)
	return tonumber(ffi.cast("uintptr_t",ffi.cast("void *", cdata)))
end

local function start(type, align)
	if started then
		error("allocating")
	end
	started = true
	local size = ffi.sizeof(type)
	totalLength = alignedSize(size)
	_align = align or ffi.sizeof("intptr_t")
	targettype = type
	commandNum = 0
	stringbuffer = {}
	callbacks = {}
	return { 0, type, {} }
end

local function pushCommand(cmd)
	command[commandNum + 1] = cmd
	commandNum = commandNum + 1
end

local function pushSetReferencesCommand(toffset, koffset, voffset)
	local cmd = {}
	cmd.cmd = "setReference"
	cmd.toffset = toffset
	cmd.koffset = koffset
	cmd.voffset = voffset
	pushCommand(cmd)
end

local function pushSetValueCommand(toffset, koffset, ktype, value)
	local cmd = {}
	cmd.cmd = "setValue"
	cmd.toffset = toffset
	cmd.koffset = koffset
	cmd.ktype = ktype
	cmd.value = value
	pushCommand(cmd)
end

local commandFuncs =
{
	setReference = function(chunk, cmd)
		local krawptr = chunk + cmd.toffset + cmd.koffset
		local kptr = ffi.cast("int*", krawptr)
		local vptr = ffi.cast("intptr_t", ffi.cast("void *", chunk + cmd.voffset))
		kptr[0] = vptr
	end,
	setValue = function(chunk, cmd)
		local krawptr = chunk + cmd.toffset + cmd.koffset
		local kptr = ffi.cast(cmd.ktype .. "*", krawptr)
		kptr[0] = cmd.value
	end
}

local function executeCommand(chunk)
	for i = 1, commandNum do
		local cmd = command[i]
		commandFuncs[cmd.cmd](chunk, cmd)
	end
end

local function copyStrings(chunk)
	for str, offset in pairs(stringbuffer) do
		local voffset = chunk + offset
		ffi.copy(voffset, str)
	end
end

local function complete()
	local chunk = ffi.new("int8_t[?]", totalLength)
	local target = ffi.cast(targettype .. "*", chunk)
	executeCommand(chunk)
	copyStrings(chunk)
	local cbs = callbacks
	
	totalLength = 0
	commandNum = 0
	callbacks = nil
	started = false
	stringbuffer = nil
	
	return target, chunk, cbs
end

local function malloc(type)
	local size = ffi.sizeof(type)
	local offset = totalLength
	totalLength = totalLength + alignedSize(size)
	return { offset, type, {} }
end

local function mallocString(str)
	local offset
	if stringbuffer[str] == nil then
		local size = string.len(str) + 1
		offset = totalLength
		stringbuffer[str] = offset
		totalLength = totalLength + alignedSize(size)
	else
		offset = stringbuffer[str]
	end
	return { offset, "string", {} }
end

local function setReference(t, k, v)
	if v == nil then return end
	
	pushSetReferencesCommand(t[OFFSET], ffi.offsetof(t[TYPE], k), v[OFFSET])
	t[FAKESELF][k] = v
	return t
end

local function setValue(t, ktype, k, value)
	pushSetValueCommand(t[OFFSET], ffi.offsetof(t[TYPE], k), ktype, value)
	t[FAKESELF][k] = value
	return t
end

local function createReference(t, ktype, k)
	local v = malloc(ktype)
	setReference(t, k, v)
	return v
end

local function setString(t, k, str)
	if str == nil then 
		return
	end
	local v = mallocString(str)
	return setReference(t, k, v)
end

local function setCallback(t, cbtype, k, luafunction)
	local fficb = ffi.cast(cbtype, luafunction)
	local fficbptr = cdata2rawptr(fficb)
	callbacks[fficbptr] = fficb
	return setValue(t, cbtype, k, fficb)
end

return 
{
	start = start,
	setReference = setReference,
	setValue = setValue,
	setString = setString,
	setCallback = setCallback,
	createReference = createReference,
	malloc = malloc,
	complete = complete,
	FAKESELF = FAKESELF,
}