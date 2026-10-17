# Jetson Nano実機起動・GPU検証手順

最終更新: 2026-10-18。対象: **初代Jetson Nano 4GB**、SDカード（64GBの手持ち）、Ubuntu 24.04 (Noble) + Armbian mainline/current。

## 1. SDカードを書き込む前に

1. 元の64GB SDカードは必ずバックアップ、できれば **別のmicroSD** で試験する。
2. [Actions](https://github.com/2rwa/tmp-jetson-nano/actions/workflows/build.yml) の完了状態を確認する。CIでイメージができても実機起動は別判定。
3. [Releases](https://github.com/2rwa/tmp-jetson-nano/releases) の実験用 `.img.xz` と `SHA256SUMS.txt` を同じ場所にダウンロードする。
4. 書き込む側のPCで `sha256sum -c SHA256SUMS.txt` を実行し、整合性を確認。
5. `lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS` などで対象デバイスを確認。**デバイス名を推測してddを実行しない**。
6. Etcherなどのイメージ書き込みツールで `.img.xz` をmicroSDに書き込む。起動時に領域拡張が発生する場合がある。

## 2. UART起動ログの取得

**Raspberry Pi 3からGPIO直結で収集する場合は [Pi 3 UART配線・初期設定ガイド](RPI3-UART.md) を参照。**



初期のLinux 6系移植ではHDMIが出ない可能性があるため、**UART接続を先に準備**する。

- USB–TTLシリアル変換器は **3.3Vロジック**（RS-232電圧を接続しない）。
- **115200 bps / 8N1** でログ取得。
- ボードのリビジョン **A02/B01でUART接続位置が異なる**。ピン配置を現物とNVIDIA公式ユーザーガイドで必ず照合する。A02のJ44とB01のJ50を混同しない。
- ボードからUSB–TTL変換器への給電線を安易に接続しない。通常、信号GND・TX・RXを正しく配線する。

参考: [NVIDIA Jetson Nano Developer Kit User Guide](https://developer.download.nvidia.com/embedded/L4T/r32-3-1_Release_v1.0/Jetson_Nano_Developer_Kit_User_Guide.pdf)。

```bash
# シリアルデバイス名は接続環境に応じて確認する
ls -l /dev/serial/by-id/ /dev/ttyUSB* 2>/dev/null
# 例: screen。デバイスは実機に合わせる
screen -L /dev/ttyUSB0 115200
```

## 3. 成功判定（CIと実機を混同しない）

| 段階 | 必要な証拠 | 状態 |
|---|---|---|
| CI構築・xz完全性 | Actionsログ / SHA256SUMS | [最新Actionsを参照](https://github.com/2rwa/tmp-jetson-nano/actions/workflows/build.yml) |
| UEFI/GRUBからLinux起動 | UARTログ | 未検証 |
| rootfs mount / login | rootシェルと `uname -a` | 未検証 |
| Ethernet / SSH | NIC認識・ログイン | 未検証 |
| DRM / HDMI | `/dev/dri`、モード設定と目視 | 未検証 |
| Nouveau GPU | dmesg、Mesa renderer、シェーダーFPS | 未検証 |
| WPE WebKit / WebGL | ソフトウェア描画でないことを実測 | 未検証 |

## 4. 起動できたら取得するログ

```bash
uname -a
cat /etc/os-release
cat /proc/device-tree/model 2>/dev/null
ls -l /dev/dri/ 2>/dev/null
lsmod | grep -E 'nouveau|drm|tegra' || true
dmesg | grep -Ei 'nouveau|drm|tegra|venc|firmware' | tail -n 100
free -h
df -h
ip -br addr
```

GUI・EGLが稼働してから `eglinfo`、`glmark2-es2`、`glxinfo -B`（X11時のみ）、`vulkaninfo`（該当する場合）を確認する。`llvmpipe` などソフトウェアrendererでの成功をGPUハードウェア成功扱いしない。

## 5. 先行事例とトラブルシューティング

- [hillac氏のJetson Nano 4GB / Armbian 26起動記録](https://github.com/hillac/jetson-nano-armbian-build/blob/main/jetson-armbian-26.md): Debian Trixie / Linux 6.18.29でUARTログイン成功、**HDMI未動作**。USBストレージ起動環境での検証であり、こちらのmicroSDとは条件が異なる。
- この事例ではDTBの `venc` reset依存でエラー（`failed to get resets for venc: -517`）が発生し、DTBを書き換えて起動した。phandle数値はDTB固有で、異なるビルドへコピーしてよいとは限らない。
- [Armbian 23 / Linux 6.1.50の旧事例](https://github.com/hillac/jetson-nano-armbian-build/blob/main/jetson-armbian-23.md): 最小イメージでHDMI表示成功の記録。ただし現在のカーネルでの成功を意味しない。

**起動しない場合は、まずUART全ログと電源・ボードrevision・SD書き込みの情報を残す。** 変更パッチは実機ログに対応して最小限導入する。

関連: [ビルド構成](BUILD-NOTES.md) / [進捗計画](PLAN.md)。
