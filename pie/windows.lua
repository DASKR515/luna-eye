local ffi = require("ffi")
ffi.cdef([[
    typedef void* HANDLE;
    typedef unsigned long DWORD;
    typedef int BOOL;
    typedef struct _MODULEINFO { void* lpBaseOfDll; DWORD SizeOfImage; void* EntryPoint; } MODULEINFO, *LPMODULEINFO;
    HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
    BOOL ReadProcessMemory(HANDLE hProcess, const void* lpBaseAddress, void* lpBuffer, size_t nSize, size_t* lpNumberOfBytesRead);
    BOOL WriteProcessMemory(HANDLE hProcess, void* lpBaseAddress, const void* lpBuffer, size_t nSize, size_t* lpNumberOfBytesWritten);
    BOOL VirtualProtectEx(HANDLE hProcess, void* lpAddress, size_t dwSize, DWORD flNewProtect, DWORD* lpflOldProtect);
    BOOL CloseHandle(HANDLE hObject);
    DWORD GetCurrentProcessId();
    BOOL EnumProcessModules(HANDLE hProcess, HANDLE* lphModule, DWORD cb, DWORD* lpcbNeeded);
    DWORD GetModuleBaseNameA(HANDLE hProcess, HANDLE hModule, char* lpBaseName, DWORD nSize);
    BOOL GetModuleInformation(HANDLE hProcess, HANDLE hModule, LPMODULEINFO lpmodinfo, DWORD cb);
]])
local M = {}
local psapi = ffi.load("psapi")
function M.list_processes()
	local procs = {}
	local h = io.popen("tasklist /NH /FO CSV")
	if not h then
		return nil
	end
	for line in h:lines() do
		local name, pid = line:match('^"([^"]+)","(%d+)"')
		if name and pid then
			table.insert(procs, { pid = tonumber(pid), name = name })
		end
	end
	h:close()
	return procs
end
function M.list_modules(hProc)
	local mods, hMods, cb = {}, ffi.new("HANDLE[1024]"), ffi.new("DWORD[1]")
	if psapi.EnumProcessModules(hProc, hMods, ffi.sizeof(hMods), cb) ~= 0 then
		for i = 0, (cb[0] / ffi.sizeof("HANDLE")) - 1 do
			local nBuf, mInf = ffi.new("char[256]"), ffi.new("MODULEINFO")
			psapi.GetModuleBaseNameA(hProc, hMods[i], nBuf, 256)
			psapi.GetModuleInformation(hProc, hMods[i], mInf, ffi.sizeof(mInf))
			table.insert(
				mods,
				{
					name = ffi.string(nBuf),
					start = ffi.cast("uintptr_t", mInf.lpBaseOfDll),
					stop = ffi.cast("uintptr_t", mInf.lpBaseOfDll) + mInf.SizeOfImage,
				}
			)
		end
	end
	return mods
end
function M.read_memory(hProc, addr, size)
	local buf, read = ffi.new("char[?]", size), ffi.new("size_t[1]")
	return ffi.C.ReadProcessMemory(hProc, ffi.cast("void*", addr), buf, size, read) ~= 0 and ffi.string(buf, size)
		or nil
end
function M.write_memory(hProc, addr, data)
	local old = ffi.new("DWORD[1]")
	local sz = #data
	if ffi.C.VirtualProtectEx(hProc, ffi.cast("void*", addr), sz, 0x40, old) ~= 0 then
		local res = ffi.C.WriteProcessMemory(hProc, ffi.cast("void*", addr), data, sz, ffi.new("size_t[1]"))
		ffi.C.VirtualProtectEx(hProc, ffi.cast("void*", addr), sz, old[0], old)
		return res ~= 0
	end
	return false
end
return M
