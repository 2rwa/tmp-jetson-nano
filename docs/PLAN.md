# Jetson Nano Mainline 実験計画と判定基準

最終更新: 2026-10-18。対象: 初代Jetson Nano 4GB / microSD 64GB / Ubuntu 24.04 Noble。

## 検証ステージ

| 段階 | CIで確認できる内容 | 実機必須の内容 | 判定 |
|---|---|---|---|
| A. image | kernel/rootfs/image生成、xz・SHA256 | なし | **成功（[Build #1](BUILD-RESULT-001.md)）** |
| B. boot | DTBパッケージの存在 | UART、rootfs mount、login | 未検証 |
| C. network | ルートfs内の設定 | Ethernet/SSH疎通 | 未検証 |
| D. display | DRM対応のカーネル設定 | HDMI、KMS mode、描画 | 未検証 |
| E. GPU | Nouveau/Mesaのパッケージ導入 | hardware renderer、クロック、FPS | 未検証 |
| F. browser | WPE/WEBGLビルド成立 | GLES/WebGL/WPEがGPUで動作 | 未検証 |

**すべての実機項目はログや実測が得られるまで「未検証」**。CI成功を実機成功と記載しない。

## 直近の進捗

- **2026-10-18：CI初回ビルド成功。** Linux **6.18.57-current-arm64** と Ubuntu 24.04 Noble MinimalのSD用イメージ生成、xz検査、チェックサム、GitHub Release公開まで完了。
- Release: [nano-noble-run-1](https://github.com/2rwa/tmp-jetson-nano/releases/tag/nano-noble-run-1)。圧縮後1.10GB、圧縮前約4.9GB。
- **次の実験はNIC/DHCPによるヘッドレス起動確認が先**。ping/DHCPが取れなければPi 3で115200bpsのUARTログを取り、必要ならDTBの問題を特定する。[NIC起動確認の詳細](NIC-BOOT-CHECK.md)
- HDMI・Nouveau GPU・WebGLは未検証。完了扱いにしない。
- [Build #1実測記録](BUILD-RESULT-001.md)

## QEMUスモークテスト

- 既存ReleaseをARM64のQEMU virtマシン上で起動する独立ジョブを追加。検証対象はLinuxカーネル・initramfs・rootfsで、**Jetson NanoのBootROM/DTB/NIC/HDMI/GPUをエミュレートしない**。
- 判定結果は[QEMUのActions](https://github.com/2rwa/tmp-jetson-nano/actions/workflows/qemu-boot.yml)と診断artifactで確認する。詳細は[QEMUブートテスト](QEMU-BOOT-TEST.md)。

## 現在の方針

- 最初はArmbianの \`BOARD=jetson-nano BRANCH=current RELEASE=noble BUILD_MINIMAL=yes\`。
- Linux 6.18.29で既知の先行事例はDebian Trixie。Ubuntu 24.04での起動は別途検証。
- 上流の \`jetson-nano.eos\` は公式サポート終了。エラー発生時はkernel-onlyとrootfs生成に分けて原因追跡。
- ブート可能になってからNouveau / MesaのGPUを試す。NVIDIA旧独自ドライバを同じrootfsに追加して結果を混同しない。
- firmware・GPUクロック・HDMIについては、確実な一次ログを残してからパッチを導入。
- 64GB microSDは実機用。Actionsディスク不足とは別問題。

## 実験ごとに記録する情報

1. コミットSHA、Actions run URL、コンパイル結果・ログ。
2. Armbian framework SHA、カーネルバージョン、Ubuntuパッケージ版、DTB識別情報。
3. microSDブート時のUARTログ、電源、ボードrevision (A02/B01)。
4. Ethernet、HDMI、DRM/KMSの状態。
5. Nouveauの初期化ログ、Mesa renderer、OpenGL ES/WebGLの測定FPS。
6. 成功と失敗の範囲、再現手順、次に試す差分。

## 今後のドキュメント運用

- [Pages](https://2rwa.github.io/tmp-jetson-nano/) の最新ビルド状態はGitHub APIをブラウザから随時取得（表示中90秒ごと、または手動更新）。
- 実機試験に関する文章は検証完了後にGitHubの文書・Pagesへ反映。
- Releaseへ配布したSDイメージは、各実験のタグ・チェックサムと一緒に追跡する。
- 未確認事項は未確認と表示し、予測と観測を区別する。
