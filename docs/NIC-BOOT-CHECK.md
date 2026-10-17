# UARTなしでJetson NanoのNICから起動を確認する

調査日: 2026-10-18 JST。対象は [Build #1 Ubuntu 24.04 Noble / Linux 6.18.57](BUILD-RESULT-001.md) の **初代Jetson Nano 4GB** 向け最小イメージ。

## 結論

**Ethernetでの自動DHCP接続を試せる構成がビルド済み。** ただし実機でのネットワーク動作は未検証。*ping成功ならLinuxのネットワーク処理まで到達した証拠。pingが返らなくても起動失敗とは限らない。*

## CIとソースから確認した証拠

| 項目 | 事実 | 限界 |
|---|---|---|
| PCIeホスト | Armbian currentの `CONFIG_PCI_TEGRA=y` | 実機でPCIeルートポートが動くかは別 |
| Realtek Ethernet | `CONFIG_R8169=m`。Actionsの実際のログに `LD [M] drivers/net/ethernet/realtek/r8169.ko`、`INSTALL .../r8169.ko` | NICのPCIe認識・ファームウェア・通信実績ではない |
| ネットワーク管理 | `net-systemd-networkd` extensionが有効。systemd-networkdのサービス作成もログで確認 | 実機systemdが到達できる必要がある |
| DHCP設定 | `/etc/netplan/10-dhcp-all-interfaces.yaml` をrootfsへ配置済み | NIC名が一致すること、ケーブル接続・DHCPサーバが必要 |
| 公式Netplan規定 | Minimalはnetworkdバックエンド、`match: { name: "e*" }` とIPv4/IPv6 DHCP | Realtek NICのインターフェース名と構成を確認 |
| ハードウェア | オリジナルJetson NanoのPCIe Realtek RTL8111/8168/8411 | ボードrevisionや個体差、ファームウェアに依存 |

公式ドキュメント: https://docs.armbian.com/user-guide/networking/  
実機Realtek型番資料: https://forums.developer.nvidia.com/t/how-is-the-gpu-wired-into-the-nano-pcie/185237  
元ビルドログ: https://github.com/2rwa/tmp-jetson-nano/actions/runs/39047832630

**注意:** 先行事例のArmbian 26.2.7はDebian Trixie + **Server**（NetworkManager）であり、手動の `nmcli` 設定を使っている。**今回のUbuntu 24.04 Minimalはsystemd-networkd/Netplan** なので、同じ `nmcli` 手順はそのまま使えない。

## UARTなしの起動確認（最初にこれを試す）

1. Jetson Nanoを有線LANで家庭内のルーターかスイッチへ接続し、電源を入れる。まず電源安定性・SDカードからの起動を確認。
2. ルーターの管理画面を開き、DHCPの払い出し一覧・LAN端末一覧を確認。Jetsonの有線LAN MACアドレスで新規エントリを探す。
3. 割り当てられたIPへ同一LANから `ping -c 4 <IP>` を実施。
4. SSHが許可されているかを `nc -vz -w 3 <IP> 22` または `ssh <user>@<IP>` で確認。ただし初回ユーザー・パスワードのセットアップが必要な場合がある。**IPがわかることとSSHログインできることは別判定。**
5. DHCP一覧で見つからなければ、Raspberry PiやMacから、LANの実際のIPv4プレフィクスを確認したうえで `nmap -sn 192.168.1.0/24` などで探索。ここでのIP帯は**例**であり家庭のネットワークに合わせて変更する。

### Raspberry PiからDHCPの発信有無を確認

Piも有線LANの同一L2セグメントへ接続した場合、以下で**DHCP Discoverなどのブロードキャスト要求**を観測できる。DHCP Offerはスイッチやルーター構成により必ずしも見えない。

```bash
sudo apt update && sudo apt install -y tcpdump
ip -br link
sudo tcpdump -ni eth0 'udp port 67 or udp port 68'
```

Pi側の有線インターフェース名は適宜変更。**Jetson由来かどうかは表示された送信元MACと、起動直後のタイミングで照合する。** 有線LANでないPiからは対象のL2トラフィックが見えない場合がある。

## NIC未確認の場合の切り分け

| 観測 | 暫定解釈 |
|---|---|
| 新規DHCP払い出し + ping応答 | Linuxカーネル・ドライバ・rootfs・ネットワークスタックがかなり先まで動作 |
| DHCP払い出しはあるがping応答なし | ネットワーク設定、ファイアウォール、ARP、ホストの停止などを追加調査 |
| ケーブルLEDだけ点灯 | PHYのリンク可能性はあるが、OS起動を意味しない |
| DHCP Discoverが見えるがアドレス付与なし | NICまでは動作している可能性があるが、DHCP応答・受信・Netplanを調査 |
| 新規DHCPエントリなし / pingなし | OSが起動していない証明ではない。PCIe/Realtek/Netplan/ブート途中停止の可能性 |

## NIC経由でログインできたら取得するデータ

```bash
uname -a
cat /etc/os-release
ip -br link
ip -br addr
networkctl status
cat /etc/netplan/*.yaml
lspci -nnk
lsmod | grep -E 'r8169|tegra'
sudo dmesg | grep -Ei 'pci|pcie|r8169|realtek|link.*up|firmware' | tail -n 100
systemctl --no-pager status systemd-networkd
```

ログインできない場合は [Raspberry Pi 3 GPIO UART](RPI3-UART.md) でシリアルログを取得。先行事例ではDTBの `venc` reset依存の修正が必要だったため、**ネットワークが見えなくてもまずUARTで原因を切り分ける**。

