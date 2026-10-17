# Jetson Nano と Raspberry Pi のイメージ互換性

更新: 2026-10-18。対象は [Release: nano-noble-run-1](https://github.com/2rwa/tmp-jetson-nano/releases/tag/nano-noble-run-1) （Ubuntu 24.04 Noble / arm64 / Linux 6.18.57）。

## 結論

- **Jetson Nano用のSDイメージを、Raspberry Pi 3に書き込んでもそのまま起動しない。** Pi 3の起動ファームウェアとDTB、カーネルのBroadcom向けサポートが必要。
- **Pi 3ではUbuntu 24.04 arm64 rootfsは流用可能。** Pi 3向けにブートパーティション・カーネル・DTB・モジュール・initramfsを組み合わせれば、同じユーザー空間を再利用できる。
- **初代 Raspberry Pi Model B 256MB はARMv6の32bit CPU。** 現在のarm64カーネルもUbuntu 24.04 arm64 rootfsも直接実行できない。別途ARMv6対応32bitディストリビューションとカーネルが必要。
- **QEMU ARM64 virtでの起動成功はPi 3の実機動作を意味しない。** QEMUテストはvirtマシンのDTBとVirtIO機器で、Nano/Pi固有の起動経路を回避している。

## SoCとOSの比較

| 観点 | Jetson Nano 4GB | Raspberry Pi 3B | Raspberry Pi初代 256MB |
|---|---|---|---|
| SoC | NVIDIA Tegra210 | Broadcom BCM2837 | Broadcom BCM2835 |
| CPU | Cortex-A57 / ARMv8-A | Cortex-A53 / ARMv8-A | ARM1176 / ARMv6 |
| CPUモード | arm64 | arm64可能 | 32bitのみ |
| GPU | NVIDIA Maxwell (Nouveau/DRM) | VideoCore IV (VC4) | VideoCore IV |
| LAN | Realtek PCIe NIC (r8169) | USB接続SMSC95XX | USB接続SMSC95XX |
| Linux起動 | NVIDIAファームウェア、UEFI/GRUBとTegra用DTB | Pi BootROM、bootcode.bin/start.elf、config.txt、Broadcom用DTB | 同系のPi旧世代ファームウェアとARMv6用カーネル |
| 今回のUbuntu 24.04 arm64 rootfs | 対象 | 流用できる | 直接実行不可 |

Pi 3 B+ のLANはLAN78xxなど別構成。テスト時は正確な機種を区別する。

## どこが共通なのか

**再利用可能:** arm64版のUbuntuユーザー空間（systemd、APT、SSH、Python、ほとんどの通常アプリケーション）とext4内のデータ。

**ボード別に用意すべきもの:**

1. Raspberry Pi起動ファームウェアとFATブートパーティション（bootcode.bin、start*.elf、fixup*.dat、config.txt）。
2. Pi 3向け64bitカーネル（Raspberry Piのkernel8.imgなど）と該当するDTB（例: bcm2710-rpi-3-b.dtb）。
3. そのカーネルバージョン用の `/lib/modules` と、ストレージ・USB・ネットワーク・HDMI/GPU等のドライバ。
4. Pi側のroot=指定、/etc/fstab、initramfs、ネットワーク初期化設定の整合。
5. Pi 3の1GBメモリで初回起動・動作に必要な容量の評価。

現行Armbian `config/kernel/linux-uefi-arm64-current.config` を確認すると、Jetsonで使う `CONFIG_PCI_TEGRA=y`、`CONFIG_R8169=m`、`CONFIG_DRM_TEGRA=m` がある。Broadcom BCM2835/2837向けのSoC設定、DRM VC4の設定は存在せず、**今回のカーネルをPi 3にそのまま使う想定ではない**。

## QEMU仮想起動との関係

[QEMUスモークテスト #2](QEMU-RESULT-002.md) は、Nano向けイメージを展開してカーネル・initramfs・ext4 rootfsを取り出し、`qemu-system-aarch64 -machine virt` の **virt用の自動生成DTBとVirtIOデバイス**で起動させた。

この方式は共通ARM64カーネルとユーザー空間のテストとして有用だが、特定の実機ボードへの互換性証明にはならない。

## Pi 3で本当に動かしたいとき

Pi 3の既知の動作する64bit OSイメージを出発点にして、必要なら今回のUbuntu Nobleのrootfs設定やパッケージを移植するのが安全。無理にJetson Nano用のGRUB/DTB/カーネルを転用しない。

## 参考

- [Raspberry Pi公式: config.txt、kernel8.img、64bit起動](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [Raspberry Pi公式: boot modesとファームウェア](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)
- [Raspberry Pi公式: Linux kernel](https://www.raspberrypi.com/documentation/computers/linux_kernel.html)
- [Armbian ARM64 current config](https://github.com/armbian/build/blob/main/config/kernel/linux-uefi-arm64-current.config)
