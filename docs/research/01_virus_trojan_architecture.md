# Kiến trúc Virus/Trojan — Cách phần mềm sống độc lập trong hệ thống

## 1. Thực thi tự động (không cần user)

### Process Injection
- **Process Hollowing** (MITRE T1055.012): CreateProcess SUSPENDED → NtUnmapViewOfSection → WriteProcessMemory → ResumeThread. Task Manager thấy svchost.exe nhưng code 100% malicious.
- **Reflective DLL Injection**: DLL tự load vào memory, không dùng LoadLibrary. Tự resolve imports bằng PEB walk. Không file trên disk, không entry trong module list.
- **Insight**: OS không verify CODE gì process chạy. Chỉ verify AI khởi động process.

### Event-Driven Execution
- **IAT Hooking**: Thay function pointer trong Import Address Table
- **Inline Hooking**: Ghi đè 5 bytes đầu của target function bằng JMP
- **WMI Event Subscriptions**: Register permanent event → chạy payload khi event fire. Survives reboot.

## 2. Persistence (sống qua reboot)

### Userland
- Registry Run Keys, Scheduled Tasks, Services, DLL Search Order Hijacking

### Kernel (Ring 0 — Rootkits)
- **SSDT Hooking**: Thay pointer trong System Service Descriptor Table → ẩn file khỏi dir listing
- **IDT Hooking**: Intercept ALL syscalls tại dispatch level
- **DKOM**: Unlink process từ _EPROCESS linked list → process vẫn chạy nhưng invisible
- **MSR Hooking**: Modify MSR 0xC0000082 (LSTAR) → intercept mọi syscall trước kernel

### Firmware/Boot
- **UEFI Bootkits** (Bootkitty 2024): Patch bootloader → load compromised kernel TRƯỚC OS
- **MBR Bootkits**: Overwrite Master Boot Record → survive OS reinstall
- **Firmware Implants** (LoJax 2018): Ghi vào SPI flash → survive disk replacement

### Fileless (Living Off the Land)
- Code chỉ tồn tại trong registry, WMI repository, hoặc memory
- LOLBins: powershell, mshta, certutil, regsvr32, wmic — trusted binaries used maliciously

## 3. Self-Replication & Self-Modification

### Polymorphic Engine
- Encrypted virus body + mutating decryptor
- Mỗi copy khác signature → static matching fail

### Metamorphic Engine (5-stage compiler pipeline)
1. Disassembler → IR
2. Shrinker (optimize)
3. Permutator (shuffle instruction order)
4. Expander (split instructions, insert junk, reassign registers)
5. Assembler → new binary

**Key insight**: Đây là self-rewriting compiler. Input = chính nó. Output = phiên bản mới của chính nó. Giống Olang self-hosting.

## 4. C2 Communication
- **DNS Tunneling**: Data encoded as subdomains. Port 53 never blocked.
- **HTTP Beaconing**: Periodic phone-home. Commands in HTML comments/EXIF/headers.
- **P2P**: Mesh topology. No central server. Kill one → others survive.
- **Abuse Legitimate Services**: Twitter, Telegram, Google Docs, Dropbox, steganography in images.

## 5. "Alive" Architecture

### Watchdog/Guardian
- Process A monitors B, B monitors A. Kill either → other respawns.
- Protection chains: A→B→C→A. Kill any one → chain restores.

### Self-Healing Triggers
- Database triggers re-insert malicious code on business events
- System's normal operations = restoration mechanism

### Biological Parallels
| Sinh học | Malware |
|----------|---------|
| Trao đổi chất | Hook vào OS scheduler, nhận CPU time |
| Cân bằng nội môi | Watchdog processes, self-healing triggers |
| Sinh sản | Polymorphic/metamorphic replication |
| Phản ứng kích thích | Event-driven hooks, WMI subscriptions |
| Thích nghi | Metamorphic engine rewrites code mỗi thế hệ |
| DNA | Mutation engine — core tồn tại qua mọi thế hệ |

## 6. 5 Nguyên tắc kiến trúc

1. **Parasitic execution**: Hijack execution context có sẵn, không tạo mới
2. **Event-driven persistence**: Hook vào events OS PHẢI xử lý
3. **Self-modifying code**: Compiler compiles chính nó thành dạng mới
4. **Redundant self-repair**: Nhiều component giám sát và phục hồi lẫn nhau
5. **Substrate independence**: Chạy DƯỚI OS → OS không thể inspect

## Áp dụng cho Nox (hợp pháp)
- Process injection → JIT compilation, dynamic code loading
- Watchdog → systemd, supervisord, Kubernetes health checks
- Self-modifying → self-hosting compilers, genetic programming
- Event-driven → io_uring, epoll, kqueue
- Kernel-level → KVM, hypervisors, eBPF

**Khác biệt không phải cơ chế — mà là ý định và sự minh bạch.**

## Sources
- Elastic: Ten Process Injection Techniques
- MITRE ATT&CK: T1055.012, T1547
- CyberArk: Fantastic Rootkits
- Eclypsium: Bootkitty Linux Bootkit
- Sansec: Self-Healing Malware
- Unit42: DNS Tunneling
- Jakob Friedl: Metamorphic Malware
- SentinelOne: Polymorphic Malware, Process Injection
- CrowdStrike: Living Off the Land
- Varonis: What is C2
- Adlice: SSDT Hooks
- Wikipedia: DKOM
- Black Hat 2004: DKOM by Jamie Butler
- Black Hat 2008: Polymorphic and Metamorphic Malware
- USENIX WOOT 2025: Stealthy Bootkit-Rootkit
- arXiv: Kernel-level Rootkit Detection
