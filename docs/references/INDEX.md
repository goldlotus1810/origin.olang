# Nox Reference Library
> 196MB+ tai lieu. Moi file co link tu specs.

## OS & Kernel

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [OSTEP.pdf](OSTEP.pdf) | 5.9MB | OS: virtualization, concurrency, persistence | Nen tang OS |
| [Linux_Kernel_Development_3rd_Robert_Love.pdf](Linux_Kernel_Development_3rd_Robert_Love.pdf) | 2.5MB | Kernel internals: process, scheduling, memory | Ky sinh dung cach |
| [OS_From_0_to_1.pdf](OS_From_0_to_1.pdf) | 6.1MB | x86 ASM, ELF, linking, OS from scratch | Bare metal |
| [littleosbook.pdf](littleosbook.pdf) | 488KB | x86 OS dev guide: boot, GDT, IDT, paging | Bare metal |
| [Writing_Simple_OS_Blundell.pdf](Writing_Simple_OS_Blundell.pdf) | 757KB | OS from scratch (Nick Blundell) | Bare metal |
| [How_to_create_OS.pdf](How_to_create_OS.pdf) | 756KB | Step by step OS creation | Bare metal |
| [xv6_book_rev11.pdf](xv6_book_rev11.pdf) | 1.1MB | MIT teaching OS (complete in 99 pages) | OS reference |
| [xv6_source_rev5.pdf](xv6_source_rev5.pdf) | 159KB | xv6 source code printout | OS reference |
| [OSDev_Wiki_offline.zip](OSDev_Wiki_offline.zip) | 125MB | OSDev.org wiki offline | Bare metal encyclopedia |

## Exokernel / Unikernel

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [Exokernel_MIT_1995.pdf](Exokernel_MIT_1995.pdf) | 184KB | Engler/Kaashoek: exokernel architecture | BP12 theory |
| [Exokernel_Thesis_MIT.pdf](Exokernel_Thesis_MIT.pdf) | 605KB | Full MIT thesis on exokernel | BP12 theory |
| [Unikraft_paper_2021.pdf](Unikraft_paper_2021.pdf) | 1.3MB | Unikraft: fast specialized unikernels | Unikernel reference |

## Hardware / Virtualization

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [Intel_SDM_Vol3_Dec2024.pdf](Intel_SDM_Vol3_Dec2024.pdf) | 8.8MB | Intel SDM Vol 3: VMX, system programming | BP12 KVM/ring-0 |
| [AMD64_APM_Vol2.pdf](AMD64_APM_Vol2.pdf) | 5.0MB | AMD64 Vol 2: SVM, system programming | BP12 KVM/ring-0 |

## KVM

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [KVM_host_few_lines.html](KVM_host_few_lines.html) | 33KB | Minimal KVM host tutorial | BP12 Phase 4 |
| [LWN_KVM_API.html](LWN_KVM_API.html) | 81KB | LWN deep dive on KVM API | BP12 Phase 4 |
| [kvm-hello-world/](kvm-hello-world/) | repo | Working KVM example (C) | BP12 Phase 4 |

## io_uring

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [io_uring_guide.pdf](io_uring_guide.pdf) | 243KB | Jens Axboe: efficient IO with io_uring | BP12 Heartbeat |

## eBPF / XDP

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [BPF_superpowers_slides.pdf](BPF_superpowers_slides.pdf) | 11MB | Brendan Gregg: BPF superpowers | BP12 Inject |
| [eBPF_lecture_2024.pdf](eBPF_lecture_2024.pdf) | 1.6MB | Columbia CS4118 eBPF lecture | BP12 Inject |
| [bpf-perf-tools-book/](bpf-perf-tools-book/) | repo | 150+ BPF tool examples | BP12 Inject |
| [xdp-tutorial/](xdp-tutorial/) | repo | XDP step by step tutorial | BP12 Inject |

## Memory / Networking

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [userfaultfd_hello_world.html](userfaultfd_hello_world.html) | 35KB | userfaultfd example | BP12 Memory |
| [raw_socket_examples.c](raw_socket_examples.c) | 2.6KB | AF_PACKET raw socket C code | BP12 Voice |

## AI / Brain

| File | Size | Noi dung | Dung cho |
|------|------|----------|----------|
| [AIMA_4th_Russell_Norvig.pdf](AIMA_4th_Russell_Norvig.pdf) | 32MB | AI: A Modern Approach (4th ed) | Brain BP2-BP9 |

## Linux Kernel Headers (copied from /usr/include/linux/)

| File | Noi dung | Dung cho |
|------|----------|----------|
| [kvm.h](kvm.h) | KVM ioctl definitions, structs | BP12 Evolution |
| [io_uring.h](io_uring.h) | io_uring SQE/CQE structs, opcodes | BP12 Heartbeat |
| [bpf.h](bpf.h) | BPF program types, map types | BP12 Inject |
| [userfaultfd.h](userfaultfd.h) | UFFDIO ioctls | BP12 Memory |
| [fb.h](fb.h) | Framebuffer ioctls, structs | BP12 Eyes |
| [V4L2_videodev2.h](V4L2_videodev2.h) | V4L2 camera ioctls | BP12 Eyes |
| [input-event-codes.h](input-event-codes.h) | Key codes, event types | BP12 Hands |
