local ffi = require("ffi")
local os_type = ffi.os
package.path = package.path .. ";./?.lua;./pie/?.lua"

local backend
if os_type == "Windows" then
	backend = require("windows") 
else
	backend = require("linux")
end
local function clear()
	os.execute(os_type == "Windows" and "cls" or "clear")
end

clear()
print([[
======================================================
  _      _    _ _   _          ______                      
 | |    | |  | | \ | |   /\   |  ____|                     
 | |    | |  | |  \| |  /  \  | |__  __   _____            
 | |    | |  | | . ` | / /\ \ |  __| \ \ / / _ \           
 | |____| |__| | |\  |/ ____ \| |____ \ V /  __/           
 |______|\____/|_| \_/_/    \_\______| \_/ \___|
======================================================
 [>] ENGINE   : LUNA-EYE v1.0 (Stable)
 [>] OPERATOR : DASKR
 [>] PLATFORM : ]] .. os_type .. [[
======================================================
]])

local LUNA = {}
LUNA.__index = LUNA
function LUNA.new(pid)
	local self = setmetatable({}, LUNA)
	self.pid = pid
	if os_type == "Windows" then
		self.handle = ffi.C.OpenProcess(0x1F0FFF, 0, pid)
	end
	return self
end
function LUNA:target()
	return os_type == "Windows" and self.handle or self.pid
end
function LUNA:find(pattern)
	local p = pattern:gsub(" ", ""):gsub("%?%?", "."):gsub("(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end)
	local mods = backend.list_modules(self:target())
	if not mods then
		return nil
	end
	local CHUNK = 1024 * 1024
	for _, m in ipairs(mods) do
		local size = tonumber(m.stop - m.start)
		for offset = 0, size - 1, CHUNK do
			local r_len = math.min(CHUNK, size - offset)
			local data = backend.read_memory(self:target(), m.start + offset, r_len + #p)
			if data then
				local pos = data:find(p, 1, false)
				if pos then
					return m.start + offset + pos - 1, m.name
				end
			end
			data = nil
		end
		collectgarbage("step")
	end
end

local function select_proc()
	io.write("[?] SEARCH PROCESS : ")
	local query = io.read():lower()
	local all = backend.list_processes()
	local res = {}
	for _, p in ipairs(all) do
		if p.name:lower():find(query) then
			table.insert(res, p)
		end
	end
	if #res == 0 then
		return nil
	end
	print("\n[#] ID    | PID    | PROCESS NAME")
	print("----|--------|----------------------")
	for i, p in ipairs(res) do
		print(string.format("[%02d] | %-6d | %s", i, p.pid, p.name))
	end
	io.write("\n[>] SELECT TARGET ID: ")
	local c = tonumber(io.read())
	return res[c] and res[c].pid or nil, res[c] and res[c].name or nil
end

local pid, name = select_proc()
if not pid then
	return
end
local eye = LUNA.new(pid)
if os_type == "Windows" and eye.handle == ffi.NULL then
	print("\n[!] Access Denied")
	return
end

print("\n[*] ATTACHED TO : " .. name)
io.write("[?] ENTER HEX PATTERN : ")
local pat = io.read()
local addr, mod = eye:find(pat)

if addr then
	print("\n[+] MATCH FOUND: 0x" .. string.format("%X", tonumber(addr)) .. " [" .. mod .. "]")
	io.write("[?] INJECT NEW DATA? (y/n): ")
	if io.read():lower() == "y" then
		io.write("[>] NEW HEX DATA : ")
		local hex = io.read():gsub(" ", ""):gsub("(%x%x)", function(h)
			return string.char(tonumber(h, 16))
		end)
		if backend.write_memory(eye:target(), addr, hex) then
			print("[+] SUCCESS")
		else
			print("[!] FAILED")
		end
	end
else
	print("[-] NOT FOUND")
end
