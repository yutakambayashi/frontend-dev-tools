# Frontend Dev Tools - 企画メモ

Claude Codeがフロントエンド（Next.js/React）を自律的に理解・操作・デバッグできるようにするためのツール統合プロジェクト。

## 背景・課題

- Claude Codeはコードだけで判断するため、UIが崩れても気づけない
- ユーザーから「動かない」と言われてもブラウザで確認できず対応が遅い
- 毎回手動でブラウザを開いて確認するのが手間

## ツール構成

### Playwright MCP（操作・観察）
- ページ遷移・クリック・入力
- スクリーンショット取得
- DOM / アクセシビリティツリー取得
- E2Eテスト実行
- ブラウザモード：デバッグ時はGUI、テスト時はヘッドレス

### Chrome DevTools MCP（デバッグ情報）
- Consoleエラー・ログ確認
- Networkリクエスト監視
- Performance分析
- DOM詳細インスペクション

### ブラウザ共有
- Playwright MCPが `--remote-debugging-port` 付きでChromiumを起動
- Chrome DevTools MCPがCDPで同じインスタンスに接続
- 操作とデバッグ情報を同一画面で取得可能に

## アーキテクチャ

```
┌─────────────────────────────────────────────┐
│              Claude Code                     │
│                                              │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │ /check-ui│  │/debug-fe │  │ /gen-e2e  │  │
│  │  スキル   │  │  スキル   │  │  スキル    │  │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│       │              │              │         │
│  ┌────▼──────────────▼──────────────▼─────┐  │
│  │         MCP サーバー層                  │  │
│  │  ┌─────────────┐  ┌─────────────────┐  │  │
│  │  │Playwright   │  │Chrome DevTools  │  │  │
│  │  │MCP          │  │MCP              │  │  │
│  │  │(操作・観察)  │  │(デバッグ情報)    │  │  │
│  │  └──────┬──────┘  └───────┬─────────┘  │  │
│  │         │    共有ブラウザ   │             │  │
│  │         └────────┬────────┘             │  │
│  └──────────────────┼──────────────────────┘  │
│                     │                         │
└─────────────────────┼─────────────────────────┘
                      ▼
            ┌──────────────────┐
            │  Chromium / Chrome│
            │  localhost:3000   │
            │  (Next.js dev)   │
            └──────────────────┘
```

## 統合形式

MCP サーバー + スキルの組み合わせ：
- **MCPサーバー層**: Playwright MCP / Chrome DevTools MCP でツールを提供
- **スキル層**: ワークフローを定義した呼び出しショートカット

### スキル案
| スキル | 用途 |
|--------|------|
| `/check-ui` | コード変更後 → dev server確認 → スクショ → レイアウト・視覚的問題の検出 |
| `/debug-frontend` | バグ報告 → ブラウザで再現 → Console/Network確認 → 原因特定 |
| `/gen-e2e` | 画面操作を記録 → E2Eテストコード生成 |

## 役割分担

| 能力 | Playwright MCP | Chrome DevTools MCP |
|------|---------------|-------------------|
| ページ遷移・クリック・入力 | **主担当** | - |
| スクリーンショット取得 | **主担当** | - |
| DOM/アクセシビリティツリー | **主担当** | 補助 |
| Consoleエラー・ログ | - | **主担当** |
| Networkリクエスト監視 | - | **主担当** |
| Performance分析 | - | **主担当** |
| E2Eテスト実行 | **主担当** | - |

## 実装フェーズ

### Phase 1: Playwright MCPセットアップ
- `settings.json` にPlaywright MCPサーバーを追加
- dev server (`next dev`) の起動をClaude Codeから実行可能に
- 基本操作を試す：ページ遷移、スクリーンショット取得、アクセシビリティツリー確認

### Phase 2: Chrome DevTools MCP追加
- Chrome DevTools MCPを追加し、Playwright MCPが開いたブラウザに接続
- Consoleエラー、Networkリクエスト、Performance情報へのアクセスを確認
- 技術的課題：同一ブラウザ共有にはPlaywrightがCDPポートを公開する設定が必要

### Phase 3: スキル化
- `/check-ui`, `/debug-frontend`, `/gen-e2e` スキルを作成
- 各スキルにワークフローを定義（dev server起動 → 操作 → 検証 → レポート）

### Phase 4: Generator/Evaluator構成（将来）
- Anthropic記事（https://www.anthropic.com/engineering/harness-design-long-running-apps）のアーキテクチャを参考
- Generator: コードを書くエージェント
- Evaluator: Playwright MCPでライブページを検証し、フィードバックを返すエージェント
- ファイルベースのハンドオフでコンテキスト効率を確保

## 設計判断

- **機能優先**: トークンコストよりもClaude Codeがブラウザを深く理解できることを重視
- **段階的実装**: Phase 1から順に進める
- **セキュリティ**: 開発環境のため特に制限なし
- **ブラウザモード**: デバッグ時はGUI（自分でも確認）、テスト時はヘッドレス
- **dev server管理**: Claude Codeに起動・停止も任せる

## 参考資料

- [Playwright CLI](https://github.com/microsoft/playwright-cli) — トークン効率重視のCLI版（今回はMCP版を採用）
- [Anthropic: Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — Generator/Evaluator分離アーキテクチャ
- Chrome DevTools MCP — CDP経由でブラウザのDevTools機能にアクセス
