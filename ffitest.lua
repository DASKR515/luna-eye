local ffi = require("ffi")

ffi.cdef[[
    int getpid();
]]

local my_pid = ffi.C.getpid()
print("--- [PIE Engine Test] ---")
print("LuaJIT FFI is: WORKING")
print("Current Process PID: " .. my_pid)
print("-------------------------")
