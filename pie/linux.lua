local ffi = require("ffi")

-- تعريف وظائف النظام المطلوبة [cite: 16, 39]
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *filename, const char *mode);
    int fclose(FILE *stream);
    char *fgets(char *s, int n, FILE *stream);
    
    int open(const char *pathname, int flags);
    int close(int fd);
    long pread(int fd, void *buf, size_t count, long offset);
]]

local M = {}

-- جلب معلومات العملية من /proc/[pid]/status [cite: 40]
function M.get_info(pid)
    local path = string.format("/proc/%d/status", pid)
    local f = ffi.C.fopen(path, "r")
    if f == nil then return nil, "العملية غير موجودة أو لا تملك صلاحيات" end

    local buffer = ffi.new("char[256]")
    local info = {}
    for i = 1, 5 do
        if ffi.C.fgets(buffer, 256, f) ~= nil then
            info[#info + 1] = ffi.string(buffer):gsub("\n", "")
        end
    end
    ffi.C.fclose(f)
    return info
end

-- قراءة الذاكرة من /proc/[pid]/mem [cite: 42, 62]
function M.read_memory(pid, address, size)
    local path = string.format("/proc/%d/mem", pid)
    local fd = ffi.C.open(path, 0) -- O_RDONLY
    if fd < 0 then return nil, "تعذر الوصول لذاكرة العملية" end

    local buffer = ffi.new("char[?]", size)
    local bytes_read = ffi.C.pread(fd, buffer, size, address)
    ffi.C.close(fd)

    if bytes_read <= 0 then return nil, "فشل قراءة الذاكرة" end
    return ffi.string(buffer, bytes_read)
end

-- استخراج الوحدات المحملة من /proc/[pid]/maps [cite: 43, 61]
function M.list_modules(pid)
    local path = string.format("/proc/%d/maps", pid)
    local f = ffi.C.fopen(path, "r")
    if f == nil then return nil, "تعذر قراءة خرائط الذاكرة" end

    local buffer = ffi.new("char[512]")
    local modules = {}
    while ffi.C.fgets(buffer, 512, f) ~= nil do
        local line = ffi.string(buffer)
        if line:match("/") then
            local addr_start, addr_end, name = line:match("(%x+)%-(%x+).-(/.+)")
            if name then
                modules[#modules + 1] = {
                    name = name:match("([^/]+)$"),
                    start = "0x" .. addr_start
                }
            end
        end
    end
    ffi.C.fclose(f)
    return modules
end

return M
