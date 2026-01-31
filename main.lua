local ffi = require("ffi")

-- [1] Backend Definitions (Updated to include pwrite)
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *filename, const char *mode);
    int fclose(FILE *stream);
    char *fgets(char *s, int n, FILE *stream);
    int open(const char *pathname, int flags);
    int close(int fd);
    long pread(int fd, void *buf, size_t count, long offset);
    long pwrite(int fd, const void *buf, size_t count, long offset);
    int getpid();
]]

-- [2] PIE Engine Class
local PIE = {}
PIE.__index = PIE

function PIE.new(pid)
    local self = setmetatable({}, PIE)
    self.pid = pid or ffi.C.getpid()
    return self
end

-- (الوظائف السابقة مدمجة هنا للسرعة)
function PIE:get_info()
    local f = ffi.C.fopen(string.format("/proc/%d/status", self.pid), "r")
    if not f then return nil end
    local info, buffer = {}, ffi.new("char[256]")
    for i = 1, 5 do if ffi.C.fgets(buffer, 256, f) ~= nil then info[#info+1] = ffi.string(buffer):gsub("\n", "") end end
    ffi.C.fclose(f); return info
end

function PIE:list_modules()
    local f = ffi.C.fopen(string.format("/proc/%d/maps", self.pid), "r")
    if not f then return nil end
    local modules, buffer = {}, ffi.new("char[512]")
    while ffi.C.fgets(buffer, 512, f) ~= nil do
        local line = ffi.string(buffer)
        local s, e = line:match("(%x+)%-(%x+)")
        local path = line:match("/.+") or "[Anonymous]"
        modules[#modules+1] = {name=path:match("([^/]+)$") or path, start=tonumber(s, 16), stop=tonumber(e, 16)}
    end
    ffi.C.fclose(f); return modules
end

function PIE:read(addr, size)
    local fd = ffi.C.open(string.format("/proc/%d/mem", self.pid), 0)
    if fd < 0 then return nil end
    local buf = ffi.new("char[?]", size)
    local n = ffi.C.pread(fd, buf, size, ffi.cast("long", addr))
    ffi.C.close(fd); return n > 0 and ffi.string(buf, n) or nil
end

-- الميزة الجديدة: الكتابة في الذاكرة
function PIE:write(addr, data)
    -- O_RDWR في لينكس قيمتها عادة 2
    local fd = ffi.C.open(string.format("/proc/%d/mem", self.pid), 2)
    if fd < 0 then return false, "فشل فتح الذاكرة للكتابة (تحتاج صلاحيات أعلى)" end
    local n = ffi.C.pwrite(fd, data, #data, ffi.cast("long", addr))
    ffi.C.close(fd)
    return n > 0
end

function PIE:find_string(str)
    local mods = self:list_modules()
    for _, m in ipairs(mods) do
        local size = m.stop - m.start
        if size > 0 and size < 5000000 then -- 5MB limit
            local data = self:read(m.start, size)
            if data then
                local pos = data:find(str, 1, true)
                if pos then return m.start + pos - 1 end
            end
        end
    end
    return nil
end

-- [3] Test execution
local engine = PIE.new()
print("--- PIE Final Stress Test ---")
local addr = engine:find_string("luajit")

if addr then
    print(string.format("[+] Found 'luajit' at: 0x%X", addr))
    -- تجربة تعديل الذاكرة (تنبيه: هذا قد يجعل البرنامج ينهار إذا عدلت شيئاً حساساً)
    -- سنقوم بكتابة "PIE-JIT" بدلاً من "luajit" في الذاكرة
    local success = engine:write(addr, "PIE-JIT")
    if success then print("[!] Memory overwritten successfully!") end
end
