# Raspberry Pi 3 → Jetson Nano 起動ログ取得（GPIO UART）

対象: Raspberry Pi 3 / Raspberry Pi OS と初代 NVIDIA Jetson Nano Developer Kit 4GB (A02 または B01)。2026-10-18 更新。

## 方針

Raspberry Pi 3のGPIOにある3.3V TTL UARTを使う。Jetson側は**デバッグコンソール J44（A02）またはJ50（B01）**を使用する。Jetsonの40ピン拡張ヘッダー J41 と混同しない。

Pi 3は標準でBluetoothが高機能UART (PL011) を使うため、今回はBluetoothを無効化してPL011をPiのGPIO14/15へ出す。Mini UART (ttyS0) のクロック変動問題を避けるため。

## 1. Raspberry Pi 3側の設定

1. PiをLANに接続し、Raspberry Pi OSでログイン。
2. `sudo raspi-config` → **Interface Options → Serial Port**:
   - serial login shell → **No**
   - serial hardware → **Yes**
3. Raspberry Pi OS Bookworm以降は **/boot/firmware/config.txt**、古いOSなら **/boot/config.txt** に追加（既存の同じ設定があれば重複追加しない）:

   ```ini
   enable_uart=1
   dtoverlay=disable-bt
   ```

4. Bluetooth初期化を無効化して再起動:

   ```bash
   sudo systemctl disable --now hciuart
   sudo reboot
   ```

5. 再起動後にデバイスを確認:

   ```bash
   readlink -f /dev/serial0
   # 期待値: /dev/ttyAMA0
   ```

Bluetoothが必要な場合は `dtoverlay=miniuart-bt` でBluetoothをmini UARTへ移す方法もあるが、その場合はVPUクロックを固定する等の設定が必要。**今回のUARTデバッグではdisable-btを優先**する。

## 2. 3本の配線（双方電源OFFで行う）

| Raspberry Pi 3（40ピンヘッダー） | Jetson Nano B01（J50） | Jetson Nano A02（J44） |
|---|---|---|
| **物理8番 / GPIO14 TXD** | **3番 / RXD** | **3番 / RXD** |
| **物理10番 / GPIO15 RXD** | **4番 / TXD** | **2番 / TXD** |
| **物理6番 / GND** | **7番 / GND** | **6番 / GND** |

- TXとRXは**交差接続**、GNDは共通。
- 3.3V/5V電源ピンやその他の信号線は**接続しない**。PiとJetsonは**それぞれ独立した電源**で動かす。
- A02/B01の区別: **A02はCSIカメラコネクター1つ、B01は2つ**。実機基板の表記とJ44/J50のシルク印刷で最終確認。
- J50（B01）はJetsonモジュール下、microSDスロット近く。J44（A02）はボード裏側のシルク印刷を確認する。
- JetsonHacksの写真・ピン配置: https://jetsonhacks.com/2019/04/19/jetson-nano-serial-console/

## 3. Raspberry Pi 3でUART起動ログを採取

```bash
sudo apt update
sudo apt install -y picocom
# Jetsonの電源を入れる「前」にPiで起動
sudo picocom -b 115200 /dev/serial0
```

起動ログを恒久保存する場合:

```bash
mkdir -p ~/jetson-logs
script -f -c 'sudo picocom -b 115200 /dev/serial0' \
  "$HOME/jetson-logs/jetson-$(date +%Y%m%d-%H%M%S).log"
```

終了: **Ctrl+A → Ctrl+X**。速度は115200 bps / 8N1。Pi 3にSSH接続すれば、Macなどからログが読める。

## 4. 表示されない場合

1. Jetsonの電源LEDや電源仕様、UARTのGND/TX/RXを確認。
2. Jetson A02/B01で**正しいデバッグヘッダー**とピン番号を選択しているか再確認。
3. `readlink -f /dev/serial0` が ttyAMA0か確認（Pi側の設定不備を検出）。
4. Pi側でserial login consoleが無効か確認。別のプログラムがUARTを使っていないか確認。
5. Jetsonの電源ONより先に `picocom` を起動する。起動後に接続すると初期ログを見逃す。
6. 初期ログは取得できたが後半で停止した場合は、`jetson-uart.log` を保存し、ブートローダー/カーネル/DTBのどこで停止したか切り分ける。

## 参考（実機のピン配列は下記で照合）

- [Raspberry Pi公式 UART説明](https://www.raspberrypi.com/documentation/computers/configuration.html)
- [JetsonHacks 初代Nano J44/J50デバッグ接続](https://jetsonhacks.com/2019/04/19/jetson-nano-serial-console/)
- [NVIDIA Jetson Nano 4GB Developer Kit User Guide](https://developer.download.nvidia.com/embedded/L4T/r32-3-1_Release_v1.0/Jetson_Nano_Developer_Kit_User_Guide.pdf)

次: [BOOT-TEST](BOOT-TEST.md) でLinux 6系/HDMI/DRM/Nouveauの起動確認。
