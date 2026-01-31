local ffi = require("ffi")

-- تعريف دالة بسيطة من الـ C Library لجلب الـ PID الحالي
ffi.cdef[[
    int getpid();
]]

local my_pid = ffi.C.getpid()
print("--- [PIE Engine Test] ---")
print("LuaJIT FFI is: WORKING")
print("Current Process PID: " .. my_pid)
print("-------------------------")
