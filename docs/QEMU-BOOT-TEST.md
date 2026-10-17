# ARM64仮想起動テスト（QEMU smoke test）

最終更新: 2026-10-18 JST。

**目的:** 既存のUbuntu 24.04 Noble / Linux 6.18.57 Jetson Nano用SDカードイメージから、*同じLinuxカーネル、initramfs、rootfs* をQEMU ARM64の汎用 `virt` マシンでブートし、Linuxとユーザー空間が起動するかを検証する。

**これはJetson Nanoのハードウェアエミュレーターではない。** QEMUの `virt` はTegra210、BootROM/UEFI、Realtek PCIe NIC、HDMI/SOR、Maxwell GPUを再現しない。Nano向けDTBはQEMUのDTBに置き換える。テストに成功してもNanoの実機起動、HDMIやGPUは**未検証**のまま。

## Actions

- [QEMUスモークテストのワークフロー](../.github/workflows/qemu-boot.yml)
- [Actionsの実行一覧](https://github.com/2rwa/tmp-jetson-nano/actions/workflows/qemu-boot.yml)
- [実装スクリプト](../scripts/qemu-boot-smoke.sh)
- [入力となる既存Release](https://github.com/2rwa/tmp-jetson-nano/releases/tag/nano-noble-run-1)

パブリックrepo向け無料の **ubuntu-24.04-arm** ネイティブARM64ランナーで実行。QEMUはKVMを前提とせずTCGで動作させる（実行環境により比較的低速）。

1. Releaseから `.img.xz` と `SHA256SUMS.txt` をダウンロードして照合。
2. 圧縮イメージを展開（約4.9GB）。ループデバイスでext4 rootfsのパーティションを読み取り専用マウント。
3. 実際の `/boot/vmlinuz-*` と `/boot/initrd.img-*` を抽出。rootfsに `/sbin/init` があることを検証。
4. `qemu-system-aarch64 -machine virt -kernel ... -initrd ... -append 'root=/dev/vdaN console=ttyAMA0 ...'` で直接Linuxをブート（Nano固有のGRUB/DTB起動経路はバイパス）。
5. **同じイメージのディスクをQEMUにスナップショット付きで接続**。公開Releaseのファイルは変更しない。
6. ログにsystemd、multi-user/login、カーネルパニック、rootfsのマウント失敗があるかを解析。
7. 成功/失敗にかかわらずシリアルログと診断情報を30日保持するActions artifactへ保存。

## 成功条件と限界

| 判定 | 内容 |
|---|---|
| PASS | Linuxが起動しrootfsをマウントし、systemdからログインまたはmulti-userまで到達 |
| PARTIAL | systemdが立ち上がるが、login/multi-userの到達がログで確認できない |
| FAIL | カーネルパニック、rootfsマウント失敗、またはsystemd起動が確認できない |
| 実機起動 | QEMUでPASSでもJetson Nano実機では**未検証** |
| GPU/NIC/HDMI | QEMU仮想デバイスの試験でありJetson実機の検証ではない |

**本テストはrootfs・カーネルの統合テストを補強するもの。** Pi 3でのUARTとDHCP/NICの実機テストは別に行う。

## 実行方法

Actionsから「QEMU ARM64 boot smoke test」 → **Run workflow** → `release_tag` を指定（初期値 `nano-noble-run-1`）。自動的にもワークフロー/スクリプト変更コミット時に走る。従来のフルイメージ再ビルドは不要。

参考: [QEMU Direct Linux Boot](https://www.qemu.org/docs/master/system/linuxboot.html) / [GitHub ARM64 runner](https://github.blog/changelog/2025-08-07-arm64-hosted-runners-for-public-repositories-are-now-generally-available/)。

## 実行履歴

- [Run #1](https://github.com/2rwa/tmp-jetson-nano/actions/runs/39080088095): アーカイブのダウンロード、SHA256一致、GPTを確認。GitHub ARMランナー上ではループデバイスのFSTYPE/LABELが空だったため、rootfs検出で終了。**QEMUはまだ起動しておらず、Linux起動失敗ではない。** GPTの `rootfs` パーティション名から番号を取得する方法へ修正し再実行。

- [Run #2](https://github.com/2rwa/tmp-jetson-nano/actions/runs/39080262634): **PASS**。GPTを直接読んでext4 rootfsをマウント、カーネルとinitrdを抽出。QEMU ARM64 virtでLinux起動、multi-user.target、jetson-nano loginまで到達。[結果とログの詳細](QEMU-RESULT-002.md)。実機用DTBと物理NIC/HDMI/GPUは試していない。
