# First-boot and GPU validation plan

Target: original Jetson Nano Developer Kit 4GB, Ubuntu 24.04 (Noble), Armbian mainline **current** kernel. The actual kernel revision will be determined by the build output; it is **not pinned** to 6.18 yet.

## Before flashing

- Save the original 64GB microSD contents or use a spare card. Do not destroy a working JetPack installation.
- Locate the **experimental** `.img.xz` and `SHA256SUMS.txt` in [Releases](https://github.com/2rwa/tmp-jetson-nano/releases).
- Verify `sha256sum -c SHA256SUMS.txt` in the download directory.
- Confirm the correct device with `lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS`. Never guess a device path.
- Use a suitable disk imaging utility to write the full `.img.xz` to the microSD, then sync/eject. Initial image partitions may expand at first boot.
- Have a **3.3V USB-to-TTL UART** adapter available (not RS-232 voltage). Baud: **115200 8N1**.

## Boot milestones (report each separately)

| Stage | Evidence | Status |
|---|---|---|
| CI build and compressed image integrity | Actions run + SHA256SUMS.txt | not yet run |
| UEFI / bootloader loads kernel | UART output | untested |
| Kernel mounts rootfs | login prompt over UART | untested |
| Ethernet / SSH | interface and link + login | untested |
| HDMI + DRM/KMS | monitor + /dev/dri enumeration | untested |
| Nouveau GPU initialization | dmesg / modinfo / renderer | untested |
| OpenGL ES and WPE WebKit | hardware renderer + measured FPS | untested |

## Previously reported hardware-specific caveat

A community developer booted Armbian 26.2.7 / Linux 6.18.29 with **Debian Trixie** on a Jetson Nano 4GB A02, using USB storage and UART. HDMI did **not** work in that report.

Their boot failure `failed to get resets for venc: -517` was worked around by removing one reset dependency from the `venc` device-tree block, recompiling the DTB, and keeping a backup of the original. Do not apply the exact numeric phandles blindly: they depend on the DTB being edited.

- [Detailed upstream reference](https://github.com/hillac/jetson-nano-armbian-build/blob/main/jetson-armbian-26.md)
- [Earlier Armbian 23 / 6.1.50 experience, HDMI worked](https://github.com/hillac/jetson-nano-armbian-build/blob/main/jetson-armbian-23.md)

If the first boot fails, collect complete UART output before changing the DTB or boot arguments.

## Once logged in (read-only diagnostics)

```bash
uname -a
cat /etc/os-release
cat /proc/device-tree/model
ls -l /dev/dri/ || true
lsmod | grep -E 'nouveau|drm|tegra' || true
dmesg | grep -Ei 'nouveau|drm|tegra|venc|firmware' | tail -n 100
free -h
df -h
ip -br addr
```

Once the display stack is installed and initialized, compare `eglinfo`, `glmark2-es2`, `vulkaninfo` (if applicable) and `glxinfo -B` (only inside an X11 session). Reject software rendering (`llvmpipe`) as a GPU pass. `/dev/dri` and `lsmod` alone do not prove acceleration.

## Next changes after the baseline

- Capture kernel SHA, DTS/DTB, GPU clocks and Mesa version in reproducible reports.
- Add a targeted, version-specific `userpatches/` device-tree fix **after** boot log evidence.
- Attempt HDMI first, then Nouveau acceleration and WPE WebKit.
- Keep vendor L4T/CUDA and mainline Nouveau results clearly separated.
