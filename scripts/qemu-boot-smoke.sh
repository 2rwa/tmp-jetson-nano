#!/usr/bin/env bash
# Execute on an ARM64 Ubuntu Actions runner, using the existing Nano release image.
# Boots its kernel and rootfs on QEMU 'virt', NOT on an emulated Tegra210 SoC.
set -Eeuo pipefail

mkdir -p result extracted
loop_dev=""
mounted=0
cleanup() {
  if [ "$mounted" = 1 ]; then sudo umount extracted || true; fi
  if [ -n "$loop_dev" ]; then sudo losetup -d "$loop_dev" || true; fi
}
trap cleanup EXIT

shopt -s nullglob
archives=(image/*.img.xz)
if [ "${#archives[@]}" -ne 1 ]; then
  echo "Expected exactly one *.img.xz in image/; got ${#archives[@]}" >&2
  exit 2
fi
archive="${archives[0]}"
raw="image/nano.img"

{
  echo "release_tag=${RELEASE_TAG:-unknown}"
  echo "archive=$archive"
  echo "host_arch=$(uname -m)"
  echo "QEMU machine=virt; QEMU-generated DTB; no Jetson firmware boot"
} | tee result/image-info.txt

# The original Release is never written to; QEMU uses a disposable snapshot.
echo "Decompressing: $archive"
xz -dc "$archive" > "$raw"
file "$raw" | tee -a result/image-info.txt
sfdisk -d "$raw" | tee result/partitions.txt

loop_dev=$(sudo losetup --find --partscan --read-only --show "$raw")
sudo lsblk -p -o NAME,SIZE,FSTYPE,LABEL,PARTLABEL "$loop_dev" | tee -a result/partitions.txt
root_dev=$(sudo lsblk -pnr -o NAME,LABEL "$loop_dev" | awk '$2=="armbi_root" {print $1; exit}')
if [ -z "$root_dev" ]; then
  root_dev=$(sudo lsblk -pnr -o NAME,FSTYPE "$loop_dev" | awk '$2=="ext4" {part=$1} END {print part}')
fi
if [ -z "$root_dev" ]; then
  echo "No ext4 root partition found in the image" >&2; exit 2
fi
root_num="${root_dev##*p}"
if ! [[ "$root_num" =~ ^[0-9]+$ ]]; then
  echo "Unexpected partition path: $root_dev" >&2; exit 2
fi
echo "Root partition: $root_dev (QEMU /dev/vda$root_num)" | tee -a result/image-info.txt

sudo mount -o ro "$root_dev" extracted
mounted=1
kernel_path=$(find extracted/boot -maxdepth 1 -type f -name 'vmlinuz-*' | sort | tail -1)
initrd_path=$(find extracted/boot -maxdepth 1 -type f -name 'initrd.img-*' | sort | tail -1)
if [ -z "$kernel_path" ] || [ -z "$initrd_path" ]; then
  echo "Missing kernel or initramfs in image rootfs /boot" >&2; exit 2
fi
sudo cp "$kernel_path" result/kernel
sudo cp "$initrd_path" result/initrd.img
sudo chmod 644 result/kernel result/initrd.img
echo "kernel=$kernel_path" | tee -a result/image-info.txt
echo "initrd=$initrd_path" | tee -a result/image-info.txt
file result/kernel result/initrd.img | tee -a result/image-info.txt
# Only test if /sbin/init and systemd are present in the image; neither is added artificially.
sudo test -e extracted/sbin/init
if [ -r extracted/etc/os-release ]; then
  grep -E '^(PRETTY_NAME|VERSION_ID)=' extracted/etc/os-release | tee -a result/image-info.txt
fi
sudo umount extracted
mounted=0
sudo losetup -d "$loop_dev"
loop_dev=""

# Do not reuse Jetson Nano's tegra210-p3450-0000.dtb on QEMU virt.
# QEMU supplies its own device tree. Kernel and initramfs are from the Release.
# The same raw SD image is attached read/write via a *temporary* QEMU snapshot.
cmdline="console=ttyAMA0,115200n8 root=/dev/vda$root_num rw rootwait loglevel=6 systemd.show_status=1"
echo "cmdline=$cmdline" | tee -a result/image-info.txt
echo "Booting QEMU ARM64 for up to 420 seconds..."
set +e
timeout --signal=TERM --kill-after=10s 420s \
  qemu-system-aarch64 \
  -machine virt -cpu cortex-a57 -accel tcg,thread=multi \
  -m 1536 -smp 2 -display none -serial stdio -monitor none \
  -no-reboot -kernel result/kernel -initrd result/initrd.img \
  -append "$cmdline" \
  -drive if=none,id=sd,format=raw,file="$raw",snapshot=on \
  -device virtio-blk-device,drive=sd \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
  > result/qemu-serial.log 2>&1
qemu_exit=$?
set -e
echo "qemu_exit=$qemu_exit" | tee result/qemu-boot-result.txt

# A timeout is expected for a *running* Linux guest. A rootfs panic is not.
grep -Ea 'Linux version |Kernel command line|Run /sbin/init|systemd\[1\]|Reached target|login:|Kernel panic|VFS: Unable|Unable to mount root' \
  result/qemu-serial.log | tail -n 100 > result/guest-highlights.txt || true
tail -n 65 result/qemu-serial.log || true

if grep -Eq 'Kernel panic|VFS: Unable to mount root|Unable to mount root fs' result/qemu-serial.log; then
  echo "outcome=FAIL: guest kernel panic or root mount failure" | tee -a result/qemu-boot-result.txt
  exit 1
fi
if grep -Eq 'Reached target (Multi-User System|multi-user.target)|[Ll]ogin:|Started.*[Gg]etty' result/qemu-serial.log; then
  echo "outcome=PASS: guest reached login or multi-user target" | tee -a result/qemu-boot-result.txt
  exit 0
fi
if grep -Eq 'systemd\[1\]|systemd [0-9]+ running in system mode' result/qemu-serial.log; then
  echo "outcome=PARTIAL: systemd started, but no login/multi-user marker" | tee -a result/qemu-boot-result.txt
  exit 1
fi
echo "outcome=FAIL: no systemd or login marker; inspect serial log" | tee -a result/qemu-boot-result.txt
exit 1
