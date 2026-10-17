# Build #1: Ubuntu 24.04 Noble / Linux 6.18.57

検証日: 2026-10-18 (JST)。実行日: 2026-10-18 未明 (JST、GitHub表示はUTCの場合あり)。

## 判定

**CIイメージ生成: SUCCESS**。**実機起動: 未検証**。**HDMI/Nouveau/WebGL: 未検証**。

| 項目 | 結果 |
|---|---|
| Actions | [Run #1 — success](https://github.com/2rwa/tmp-jetson-nano/actions/runs/39047832630) |
| ソースコミット | [eecc2ef](https://github.com/2rwa/tmp-jetson-nano/commit/eecc2ef3349c59ad176a6c872c91f4f2858b7b57) |
| Release | [nano-noble-run-1](https://github.com/2rwa/tmp-jetson-nano/releases/tag/nano-noble-run-1) |
| ターゲット | 初代Jetson Nano 4GB、arm64 |
| OS | Ubuntu 24.04 Noble / minimal |
| Armbian | unofficial 26.11.0-trunk |
| カーネル | 6.18.57-current-arm64 |
| ボード用DTB | /boot/armbian-dtb-6.18.57-current-arm64 |
| DTBの元ファイル | /usr/lib/linux-image-6.18.57-current-arm64/nvidia/tegra210-p3450-0000.dtb |
| 圧縮前SDイメージ | ビルドログ表示 約4920MB（おおよそ4.9GB） |
| 圧縮後 | 1,100,928,004 bytes（約1.10 GB / 1.03 GiB） |
| xz整合性試験 | 成功 |
| SHA256SUMS.txt | 同じReleaseに公開 |
| 全ジョブ結果 | 全ステップ成功 |
| Actions実行時間 | 約107分 |
| 診断ログ | Actions artifact armbian-logs-1 (ID: 12109700746) |
| ログartifactの有効期限 | 2026-10-31 17:50 UTC (約11/1 02:50 JST) |

## ビルドログで確認できた事実

- initramfsの生成: /boot/initrd.img-6.18.57-current-arm64
- GRUB向けのDTBコピーと登録成功: /boot/armbian-dtb-6.18.57-current-arm64
- grub設定にLinuxイメージ、initrd、DTBが認識された。
- SDイメージの生成、xz圧縮、SHA256生成、xz -t の検査とReleaseアップロードが成功した。
- ビルド時のSDイメージ約4.9GBは、64GB microSDへ書き込む容量としては十分小さい。
- 先行事例のLinux 6.18.29とは異なり **Linux 6.18.57**。先行事例のDTB回避策を無条件適用しないこと。

## 注意事項

- **ビルド成功だけでは起動可能性を証明しない。** Jetson Nano用のArmbian定義は上流でEOS扱い。microSDブートについてはUART実機ログを先に確認する。
- 最小イメージにGUIデスクトップはない。起動時のserial consoleはデフォルト指定。HDMIが真っ黒でも、必ずしもHDMIハードウェアが認識されていないとは限らない。
- 正常な起動とrootfsのマウントを確認後、DRM/KMS/HDMI、Nouveau/Mesa、WebGLの順番で検証する。
- [Pi 3でUARTログを取得する手順](RPI3-UART.md) / [全般の起動テスト](BOOT-TEST.md)。

## 次回のアクション

1. 既存64GB SDカードの内容を保存する（または別microSDカードを使用）。
2. Releaseのimg.xzとSHA256SUMS.txtをダウンロードして照合し、メディアへ書き込む。
3. 初代Jetson NanoのA02/B01を判別し、Pi 3 UARTで起動ログを保存する。
4. ブートログをもとに、必要なDTBとブート設定を最小差分で修正する。
