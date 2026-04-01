#!/bin/bash
# ═══ Boot NoxOS in QEMU ═══
# Gentoo kernel + NoxOS as PID 1
#
# Usage: bash noxos/boot_qemu.sh
#
# Prerequisites:
#   /tmp/noxos_disk.img — 2GB ext4 with Gentoo stage3 + NoxOS init
#   Host kernel at /boot/vmlinuz-linux (Arch) or extracted from Gentoo

DISK="/tmp/noxos_disk.img"
KERNEL="/boot/vmlinuz-linux"  # Use host kernel

if [ ! -f "$DISK" ]; then
    echo "ERROR: $DISK not found. Run disk creation first."
    exit 1
fi

if [ ! -f "$KERNEL" ]; then
    echo "No kernel at $KERNEL, trying /boot/vmlinuz..."
    KERNEL=$(ls /boot/vmlinuz* 2>/dev/null | head -1)
    if [ -z "$KERNEL" ]; then
        echo "ERROR: No kernel found"
        exit 1
    fi
fi

echo "=== NoxOS QEMU Boot ==="
echo "Kernel: $KERNEL"
echo "Disk: $DISK"
echo "Init: /sbin/nox_init"
echo "========================"

exec qemu-system-x86_64 \
    -enable-kvm \
    -m 1024 \
    -kernel "$KERNEL" \
    -drive file="$DISK",format=raw,if=virtio \
    -append "root=/dev/vda init=/sbin/nox_init console=ttyS0 quiet" \
    -nographic \
    -serial mon:stdio \
    -no-reboot
