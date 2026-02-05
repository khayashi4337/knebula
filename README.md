# Nebula on WSL2 - Docker Service Access for Local Teams

WSL2の多段NAT環境でDockerサービスを同一LAN内のチームメンバーに公開するための[Nebula](https://github.com/slackhq/nebula)構成ガイド。

## 背景

WSL2 + Docker環境でサービス（Forgejo等）を立てると、多段NAT（社内LAN → Windows → WSL2 → Docker）により、隣の席の同僚からもアクセスできない問題が発生します。

この構成は、SlackがOSS化したメッシュVPN「Nebula」を使って、この問題を解決します。

## 構成図

```
[社内LAN: 192.168.179.0/24]
 │
 ├─ サーバPC (Windows 10 + WSL2)
 │    ├─ [Windows] UDP Relay (port 4242)
 │    └─ [WSL2] Nebula Lighthouse (192.168.100.1)
 │         └─ Docker
 │              ├─ Forgejo (port 3000)
 │              └─ etc.
 │
 ├─ メンバー1 PC ── Nebula (192.168.100.2)
 ├─ メンバー2 PC ── Nebula (192.168.100.3)
 └─ メンバー3 PC ── Nebula (192.168.100.4)
```

## 特徴

- **完全OSS**: Nebula (MIT License) のみ使用、外部サービス依存なし
- **証明書10年有効**: 仲間内利用なら実質メンテナンスフリー
- **サービス化対応**: メンバーPCでは自動起動、操作不要
- **Windows 10対応**: ミラードネットワーキング不要

## 必要なもの

### サーバ側（Lighthouse）
- Windows 10 + WSL2 (Ubuntu推奨)
- Docker Engine on WSL2
- Nebula (Linux版) - [Releases](https://github.com/slackhq/nebula/releases)

### メンバー側
- Windows 10/11
- Nebula (Windows版) - [Releases](https://github.com/slackhq/nebula/releases)
- NSSM (サービス化用) - [Download](https://nssm.cc/download)
- Wintun (Nebulaリリースに同梱)

## クイックスタート

### 1. 証明書の生成（サーバ側WSL2で実行）

```bash
# Nebulaバイナリをダウンロード・展開
wget https://github.com/slackhq/nebula/releases/download/v1.10.2/nebula-linux-amd64.tar.gz
tar xzf nebula-linux-amd64.tar.gz

# 証明書生成（10年有効）
./nebula-cert ca -name "my-team" -duration 87600h
./nebula-cert sign -name "lighthouse" -ip "192.168.100.1/24" -duration 87600h
./nebula-cert sign -name "member1" -ip "192.168.100.2/24" -duration 87600h
./nebula-cert sign -name "member2" -ip "192.168.100.3/24" -duration 87600h
./nebula-cert sign -name "member3" -ip "192.168.100.4/24" -duration 87600h
```

### 2. Lighthouse起動（サーバ側）

```bash
# WSL2で
sudo ./nebula -config config-lighthouse.yml
```

```powershell
# Windows PowerShell（別ウィンドウ、管理者権限）で
.\udp-relay.ps1
```

### 3. メンバーPCへの配布

各メンバーに以下を配布：
- `nebula.exe`
- `nssm.exe`
- `config.yml`（static_host_mapを更新済み）
- `ca.crt`, `host.crt`, `host.key`
- `install-service.bat`
- `dist/windows/wintun/bin/amd64/wintun.dll`

### 4. メンバーPCでのセットアップ

管理者が一度だけ実行：
```
install-service.bat を右クリック → 管理者として実行
```

以降、メンバーは何もしなくてOK。ブラウザで `http://192.168.100.1:3000` を開くだけ。

## ファイル構成

```
.
├── README.md
├── configs/
│   ├── lighthouse.yml.example    # Lighthouse設定テンプレート
│   ├── member.yml.example        # メンバー設定テンプレート
│   └── local-test.yml.example    # ローカルテスト用
├── scripts/
│   ├── udp-relay.ps1             # UDP転送スクリプト（Windows）
│   ├── generate-certs.sh         # 証明書生成スクリプト
│   ├── install-service.bat       # サービスインストール
│   └── uninstall-service.bat     # サービスアンインストール
└── docs/
    └── blog.txt                  # 詳細な解説記事
```

## 注意事項

### wintun.dll のパス

Nebulaは特定のパスでwintun.dllを探します：
```
C:\nebula\dist\windows\wintun\bin\amd64\wintun.dll
```

### netsh portproxy は使えない

`netsh interface portproxy` はTCPのみ対応。NebulaはUDPを使うため、PowerShellのUDPリレーが必要です。

### WSL2のIPは変わる

WSL2のIPは再起動で変わることがあります。`udp-relay.ps1` 内の `$wslIP` を更新するか、以下で自動取得：
```powershell
$wslIP = (wsl hostname -I).Trim().Split()[0]
```

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| wintun driver not found | wintun.dllのパスが違う | 上記のディレクトリ構造で配置 |
| Handshake timed out | Lighthouseに到達できない | UDPリレーが起動しているか確認 |
| Access denied | 管理者権限がない | 管理者として実行 |

## 関連リンク

- [Nebula GitHub](https://github.com/slackhq/nebula)
- [Nebula Documentation](https://nebula.defined.net/docs/)
- [NSSM - Non-Sucking Service Manager](https://nssm.cc/)
- [Wintun](https://www.wintun.net/)

## ライセンス

MIT License
