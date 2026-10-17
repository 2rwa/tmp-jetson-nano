# QEMU boot test #2 — Ubuntu Noble / Linux 6.18.57

最終更新: 2026-10-18 JST。**判定: PASS（QEMU ARM64 virt仮想マシンに限る）。**

| 項目 | 結果 |
|---|---|
| [Run #2](https://github.com/2rwa/tmp-jetson-nano/actions/runs/39080262634) | SUCCESS |
| 対象Release | [nano-noble-run-1](https://github.com/2rwa/tmp-jetson-nano/releases/tag/nano-noble-run-1) |
| テスト環境 | GitHub-hosted `ubuntu-24.04-arm` runner / aarch64 |
| 仮想マシン | `qemu-system-aarch64 -machine virt`, Cortex-A57, TCG |
| CPU・メモリ | 2 vCPU / 1536 MiB |
| カーネル | Release内の `/boot/vmlinuz-6.18.57-current-arm64` |
| initrd | Release内の `/boot/initrd.img-6.18.57-current-arm64` |
| ルートファイルシステム | 同じReleaseのGPT第2パーティション（ext4、`armbi_root`） |
| QEMU仮想ディスク | `/dev/vda2` / VirtIO block |
| 接続NIC | QEMU virtio-net（JetsonのRealtekではない） |
| GRUB/UEFI | **未試験**。カーネル直接ロード |
| DTB | QEMU virtによる自動生成。**Jetson NanoのDTBではない** |
| Kernel panic / root mount failure | なし |
| systemd | 起動確認 |
| multi-user.target | 到達 |
| login | `jetson-nano login: root (automatic login)` を観測 |
| 初回セットアップ | `Press Enter to start the first login setup on this console.` を観測 |
| 収集ログ | [Actions artifact jetson-qemu-boot-2](https://github.com/2rwa/tmp-jetson-nano/actions/runs/39080262634) |

## 実際のシリアル出力（抜粋）

```text
[  OK  ] Reached target network.target - Network.
[  OK  ] Reached target getty.target - Login Prompts.
[  OK  ] Reached target multi-user.target - Multi-User System.
[  OK  ] Reached target graphical.target - Graphical Interface.
jetson-nano login: root (automatic login)
Press Enter to start the first login setup on this console.
```

`graphical.target` はsystemdのターゲット名にすぎず、**HDMI、ディスプレイ描画、GPUドライバの成功を意味しない**。

## 検証フローの修正

- [Run #1](https://github.com/2rwa/tmp-jetson-nano/actions/runs/39080088095) はイメージのGPTを確認できたが、ループデバイスにFSTYPEが表示されずrootfs検出失敗。Linuxは未起動。
- GPTの `rootfs` パーティション名から番号を決め、`blkid -p` でext4を直接検証する方式に修正。
- Run #2でLinuxカーネル、initramfs、ext4 rootfsをQEMU virt上で起動できた。上記のログにより、ユーザー空間systemdとログイン処理が動くことを確認。

## 現時点で不明なこと

- JetsonのBootROM/UEFIからLinuxが起動するか。今回QEMUはGRUB/UEFIをバイパスしている。
- Jetson固有の `tegra210-p3450-0000.dtb` でrootfsまで到達するか。先行Armbian 26ではDTB改変が必要。
- JetsonのRealtek PCIe Ethernetがリンク・DHCP・pingまで動くか。
- HDMI / drm-tegra / Nouveau GPUが動作するか。
- **初回設定画面を経ずにSSHログインできるか**。QEMUで自動ログインの後、コンソールからEnterを促す初回セットアップ画面が出た。

このため、実機は **LANでDHCP・ping確認 → うまくいかなければPi 3 UARTログ** の順で確認する。SSHの可否だけでは起動を判定しない。

[QEMUテストの設計](QEMU-BOOT-TEST.md) / [NIC起動確認](NIC-BOOT-CHECK.md) / [Pi 3 UART](RPI3-UART.md)。
