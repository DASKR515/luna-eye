local ffi = require("ffi")
ffi.cdef([[
    typedef struct FILE FILE;
    FILE *fopen(const char *filename, const char *mode);
    int fclose(FILE *stream);
    char *fgets(char *s, int n, FILE *stream);
    int open(const char *pathname, int flags);
    int close(int fd);
    long pread(int fd, void *buf, size_t count, long offset);
    long pwrite(int fd, const void *buf, size_t count, long offset);
    int getpid();
]])
local M = {}
function M.list_processes()
	local procs = {}
	local h = io.popen("ps -e -o pid,comm --no-headers")
	if not h then
		return nil
	end
	for line in h:lines() do
		local pid, name = line:match("%s*(%d+)%s+(.+)")
		if pid and name then
			table.insert(procs, { pid = tonumber(pid), name = name })
		end
	end
	h:close()
	return procs
end
function M.list_modules(pid)
	local f = ffi.C.fopen(string.format("/proc/%d/maps", pid), "r")
	if f == nil then
		return nil
	end
	local mods, buf = {}, ffi.new("char[512]")
	while ffi.C.fgets(buf, 512, f) ~= nil do
		local l = ffi.string(buf)
		local s, e = l:match("(%x+)%-(%x+)")
		local path = l:match("/.+") or "[Anonymous]"
		if s and e then
			table.insert(
				mods,
				{ name = path:match("([^/]+)$") or path, start = tonumber(s, 16), stop = tonumber(e, 16) }
			)
		end
	end
	ffi.C.fclose(f)
	return mods
end
function M.read_memory(pid, addr, size)
	local fd = ffi.C.open(string.format("/proc/%d/mem", pid), 0)
	if fd < 0 then
		return nil
	end
	local buf = ffi.new("char[?]", size)
	local n = ffi.C.pread(fd, buf, size, ffi.cast("long", addr))
	ffi.C.close(fd)
	return n > 0 and ffi.string(buf, n) or nil
end
function M.write_memory(pid, addr, data)
	local fd = ffi.C.open(string.format("/proc/%d/mem", pid), 2)
	if fd < 0 then
		return false
	end
	local n = ffi.C.pwrite(fd, data, #data, ffi.cast("long", addr))
	ffi.C.close(fd)
	return n > 0
end
return M
