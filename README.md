# 🌙 LUNA-EYE v1.0 (Stable)

**The Ultimate Cross-Platform Memory Inspection & Injection Engine**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-green.svg)
![Language](https://img.shields.io/badge/Language-LuaJIT-orange.svg)

---

## ✨ Overview

**LUNA-EYE** is a lightweight, ultra-fast **memory inspection and injection engine** built with **LuaJIT + FFI**. It is designed for **precision, stability, and cross-platform compatibility**, allowing direct interaction with live processes on both **Windows** and **Linux**.

The engine focuses on **Binary Pattern Scanning (AOB)** and safe, controlled memory patching—without external dependencies or heavy frameworks.

---

## 🚀 Key Features

* **True Cross-Platform Core**
  Single unified codebase with OS-specific backends:

  * Windows → Win32 API (via FFI)
  * Linux → `/proc/[pid]/mem` and `/proc/[pid]/maps`

* **High-Performance Memory Scanning**
  Uses **Smart Chunking** to scan large address spaces without exhausting LuaJIT memory.

* **Advanced AOB (Array of Bytes) Scanner**

  * Wildcard support (`??`)
  * Zero external libraries
  * Optimized byte-by-byte matching

* **Dynamic Memory Protection Escalation**
  Automatically attempts to override read-only memory using:

  * `VirtualProtectEx` (Windows)
  * Permission validation via memory maps (Linux)

* **Interactive Process Manager**

  * PID-based targeting
  * Name-based filtering
  * Safe and responsive process enumeration

* **Minimal & Clean Architecture**
  Designed for hacking, research, and reverse-engineering workflows.

---

## 🧠 Project Architecture

```text
luna-eye/
├── main.lua            # Entry point & interactive CLI
└── pie/                # Platform Implementation Engine (PIE)
    ├── windows.lua     # Windows memory & process backend
    └── linux.lua       # Linux /proc-based backend
```

---

## 💻 Quick Start

### 🔧 Prerequisites

* **LuaJIT** (required for FFI support)

---

### ▶️ Execution

#### 🪟 Windows

Run the tool **as Administrator** to access protected memory regions:

```bash
.\run.ps1
```

#### 🐧 Linux

Run with **sudo** to allow access to process memory:

```bash
sudo luajit main.lua
```

---

## 🛡️ Engineering & Stress Handling

* **Access Denied Handling**
  Automatically retries memory writes by adjusting page protection (RW / RWX) when possible.

* **Memory-Safe Scanning**
  Avoids loading full modules into memory. All scans are performed in **1MB chunks**, ensuring stability even on massive processes like browsers or Electron apps.

* **System Stability First**
  Uses lightweight system calls (`tasklist`, `ps`) and avoids blocking I/O to prevent terminal freezes or deadlocks.

---

## ⚠️ Disclaimer

This project is intended **strictly for educational, research, and security analysis purposes**.

The developer **(DASKR)** assumes **no responsibility** for misuse, damage, or illegal activity resulting from the use of this software.

Use responsibly.

---

## 👨‍💻 Developer

**DASKR**
Lead Architect & Core Engineer

---

> 🌙 *LUNA-EYE — Precision over power. Control without noise.*
