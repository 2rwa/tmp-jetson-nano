# ビルド構成・リソース・設計判断

更新: 2026-10-18。対象は **初代 NVIDIA Jetson Nano Developer Kit 4GB**。Orin Nanoとは別のSoC。

## 目標と境界

- ユーザー空間: **Ubuntu 24.04 Noble / arm64**。Ubuntu公式のコンパイル済みパッケージをAPTで取得してrootfsを構成。
- カーネル: Armbianビルドフレームワークの **current** 分岐。実際のLinuxバージョンはActionsログとイメージから確認。6.18固定とはしていない。
- 専用コンポーネント: Linuxカーネル、モジュール、DTB、起動周辺。必要な場合のみクロスコンパイル。
- GPU: メインラインのNouveau + Mesa。初期イメージのGPU動作は未確認。NVIDIA L4T 4.xの専用CUDA / EGLスタックは**混ぜない**。
- 出力: microSD用圧縮イメージ .img.xz と SHA256SUMS.txt。GitではなくReleasesで配布する。

## ビルドの流れ

1. GitHub標準 ubuntu-latest ランナーでディスク空き容量確保。
2. Armbianビルドフレームワークを取得。現時点の上流ボード定義は **config/boards/jetson-nano.eos**（EOS = サポート終了扱い）。
3. \`./compile.sh requirements\` でビルド依存ツールをセットアップ。
4. \`BOARD=jetson-nano BRANCH=current RELEASE=noble BUILD_MINIMAL=yes\` でイメージ構築。
5. 圧縮イメージの \`xz -t\` と \`sha256sum\` を検証。
6. 実験用pre-releaseに公開。CIログはActions artifact（保存期限あり）。

CIは **ビルドとファイル整合性** のテスト。実機起動・HDMI・GPU性能を保証しない。

## メモリ・容量

- Armbian公式推奨: RAM 8GB以上、ディスク空き容量おおむね50GB。
- GitHub Actions標準Linuxランナー: RAM 16GB、初期ディスクは数十GB未満の場合がある。ワークフローでランナー不要データを削除する。
- rootfs内の一般的なUbuntuプログラムはコンパイル済み **ARM64パッケージ**を用いる。全パッケージをローカルビルドするわけではない。
- 圧縮Releaseイメージは先行事例で約1.2〜1.4GBだったが、Nobleについてのサイズは実測前。
- 実機64GB microSDの容量と、CIランナーのビルド作業用ディスク容量は別。GitHub Releaseは**個別ファイル2GiB未満**制限があるため、超過時は分割や縮小方式を検討。
- Armbianのキャッシュは条件により再利用できるが、常にキャッシュヒットするとは限らない。

## 最新Ubuntuを入れる難しさ

Armbian公式は2026-02にJetson Nanoの自動イメージを「起動しない」としてEOSへ移した。ビルドが通っても特定ボードで起動しない場合がある。先行のArmbian 26.2.7 / Debian Trixie / Linux 6.18.29 / Nano A02 はUSB起動・UARTログインに成功、HDMIは未動作。さらにvencノードのreset依存をDTBで修正している。**同じ数値のphandleを異なるDTBに盲目的に適用しないこと。**

## GPUの判定

1. Nouveauのカーネル初期化が完了するか（dmesg / ドライバ / firmware）。
2. DRM/KMS / HDMIの出力が正常か。
3. MesaのOpenGL ES rendererがハードウェアGPUになっているか（llvmpipeは失敗）。
4. シェーダー負荷でFPS・GPUクロック・消費電力を実測。
5. WebGL / WPE WebKit 2.54に進む。

メインラインNouveau系で**CUDA 10.2は使わない**。またMaxwell対応NVKの一般論からJetson Nano内蔵GPUでのVulkan実動作を推定しない。

## 参照

- [Armbian build](https://github.com/armbian/build)
- [Armbian Jetson Nano実験例 (h illa c)](https://github.com/hillac/jetson-nano-armbian-build)
- [Armbian 26起動レポート](https://github.com/hillac/jetson-nano-armbian-build/blob/main/jetson-armbian-26.md)
- [ArmbianボードのEOS化](https://github.com/armbian/build/commit/f76c7625165c88a9dd4701d0880b405b94deaf12)
- [GitHub Actions](../.github/workflows/build.yml)
