# tmp-jetson-nano

初代 **NVIDIA Jetson Nano Developer Kit 4GB** で **Ubuntu 24.04 Noble + メインラインLinux + Nouveau/Mesa** を試すための一時実験リポジトリです。

**[📈 実験ダッシュボード (GitHub Pages)](https://2rwa.github.io/tmp-jetson-nano/)**  
[GitHub Actions](https://github.com/2rwa/tmp-jetson-nano/actions/workflows/build.yml) · [実験イメージ (Releases)](https://github.com/2rwa/tmp-jetson-nano/releases)

## 現状と前提

- GitHub ActionsでARM64のMinimal Ubuntu 24.04イメージをビルドするワークフローを用意。
- ビルド結果はPagesに表示。実機起動・HDMI・GPU描画は**未検証**。
- ArmbianのJetson Nano定義はサポート終了扱い \`jetson-nano.eos\`。イメージが作れても起動するとは限りません。
- 使用予定の64GB microSDには既存データがあるため、書き込む前にバックアップ。
- 同系列の実験にDebian Trixie / Linux 6.18.29でUART起動できた例があるが、HDMI未動作。これはUbuntu Nobleの起動実績ではありません。
- NVIDIA JetPack旧ドライバ/CUDAと、メインラインNouveauは別経路。GPU動作判定まで混ぜない。

## 技術資料

- [アーキテクチャ、ビルド要件、容量とGPUの境界](docs/BUILD-NOTES.md)
- [SD書き込み、UART、GPU実機試験](docs/BOOT-TEST.md)
- [段階的な検証計画と判定基準](docs/PLAN.md)
- [イメージ構築ワークフロー](.github/workflows/build.yml)
- [Pages公開ワークフロー](.github/workflows/pages.yml)

## Pagesの運用

GitHub Actions配信設定なら \`pages.yml\` が \`docs/\` をデプロイします。ブランチ配信 (main /docs) でも \`docs/index.html\` を直接表示可能です。main /(root) 配信ならルート \`index.html\` が \`docs/\` へ案内します。

Pagesは公開GitHub APIから最新ActionsとReleasesを読み込んで表示を更新します（表示中90秒ごと＋更新ボタン）。**自動で更新されるのはCIとReleaseの状態だけ**。実機GPUの検証結果は実測後に文書を更新します。

## 参考

- [Armbian build framework](https://github.com/armbian/build)
- [Jetson Nano向けArmbian Actions先行事例](https://github.com/hillac/jetson-nano-armbian-build)
- [Linux 6.18.29実機起動の注意点](https://github.com/hillac/jetson-nano-armbian-build/blob/main/jetson-armbian-26.md)
