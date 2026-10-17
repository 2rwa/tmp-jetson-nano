# tmp-jetson-nano

Experimental **original NVIDIA Jetson Nano 4GB** build: Ubuntu 24.04 (Noble) userspace, modern mainline Linux from Armbian, and a future Nouveau/Mesa GPU validation track.

This repository is a **build-and-boot experiment**, not a ready-to-use official Jetson image. NVIDIA JetPack 4.6.x uses an old vendor kernel; this experiment deliberately does **not** bring over NVIDIA's proprietary CUDA/L4T driver stack.

## Current milestone

1. Build an ARM64 **minimal/headless** Ubuntu 24.04 image using GitHub Actions.
2. Validate the compressed image and publish it in [Releases](../../releases) (experimental prerelease).
3. On a spare microSD card, boot the original 4GB board and collect UART logs.
4. Resolve board-specific DTB/HDMI/USB/Ethernet issues.
5. Only after boot/display are stable: enable and measure Nouveau/Mesa, DRM/KMS, GLES/WebGL, and WPE WebKit.

**Build success is not boot success.** The upstream Armbian board definition is `jetson-nano.eos` (end-of-support / experimental). Prior community success with Armbian 26 / Linux 6.18 was **Debian Trixie, headless, with a manual DTB change**, not Ubuntu 24.04 GPU acceleration.

## GitHub Actions

- [Build workflow](.github/workflows/build.yml)
- [Actions runs](../../actions/workflows/build.yml)
- [Experimental image releases](../../releases)
- [Boot / GPU test checklist](docs/BOOT-TEST.md)

A change to the workflow or `userpatches/` starts an Ubuntu 24.04 build. **Run workflow** can also select Debian Trixie as a known community-reference userspace.

The build uses standard `ubuntu-latest` runners and frees disk space before building. The source build framework is `armbian/build` (currently main, record SHA in each run). Outputs are `.img.xz` plus SHA256SUMS.txt uploaded to GitHub Releases; failure diagnostics are saved as Actions artifacts. Nothing gets flashed automatically.

## Hardware assumptions

- **Target**: original Jetson Nano **4GB** Developer Kit; A02/B01 revision to be verified.
- **Storage**: an **additional / backed-up** microSD; an available 64 GB card is sufficient for the image size, but **64 GB of space on the card does not increase Actions runner disk space**.
- **Boot diagnostics**: 115200 bps serial console (UART), ideally a USB-to-TTL **3.3V** adapter; SSH may not work until networking is configured.
- NVIDIA proprietary drivers, CUDA and Vulkan on the vendor stack are **not included** in this mainline experiment.

## Sources

- [Community Action and Jetson Nano notes](https://github.com/hillac/jetson-nano-armbian-build)
- [Armbian build framework](https://github.com/armbian/build)
- [Armbian build requirements](https://docs.armbian.com/build-framework/getting-started/)

Do not treat upstream's `venc` DTB workaround as universally valid on every kernel / hardware revision; follow the recorded boot log and preserve the original DTB.
