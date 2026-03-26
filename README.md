# Frontend Dev Tools

Claude Code にブラウザの操作・観察・デバッグ能力を追加するツール統合プロジェクト。

Playwright MCP と Chrome DevTools MCP を組み合わせ、Claude Code がフロントエンドの「見た目」や「ブラウザ上の動作」を自律的に確認・改善できるようにする。

## 背景

Claude Code はコードの読み書きには優れているが、UI が崩れていても気づけず、Console エラーや Network リクエストも確認できない。このプロジェクトは、MCP サーバーとスキルを通じてその課題を解決する。

## アーキテクチャ

```
Claude Code
├── スキル層（/build-ui など）
│   └── Planner → Generator ↔ Evaluator ループ
└── MCP サーバー層
    ├── Playwright MCP（操作・観察）
    │   └── ページ遷移、クリック、スクリーンショット、アクセシビリティツリー
    └── Chrome DevTools MCP（デバッグ情報）
        └── Console ログ、Network リクエスト、Performance 分析
            ↓ CDP 共有
        Chromium / Chrome（localhost:9222）
```

両 MCP は Chrome DevTools Protocol（CDP）経由で同一ブラウザインスタンスを共有する。

## ディレクトリ構成

```
frontend_dev_tools/
├── README.md              ← このファイル
├── PLAN.md                ← 企画メモ（背景・ツール構成・フェーズ計画）
├── PRD.md                 ← Phase 1+2 の PRD（MCP セットアップ）
├── PRD-build-ui.md        ← Phase 4 の PRD（/build-ui スキル）
├── scripts/
│   └── ensure-chrome-cdp.sh ← Chrome CDP 自動起動スクリプト
├── docs/
│   └── setup-guide.md     ← セットアップ手順・検証チェックリスト
└── skills/
    └── build-ui/          ← /build-ui スキル
        ├── SKILL.md       ← オーケストレータ（ループ制御）
        ├── PLANNER.md     ← Planner エージェントプロンプト
        ├── GENERATOR.md   ← Generator エージェントプロンプト
        ├── EVALUATOR.md   ← Evaluator エージェントプロンプト
        └── HANDOFF.md     ← ファイルベースハンドオフプロトコル
```

## クイックスタート

### 1. Chrome を CDP ポート付きで起動

`/build-ui` スキル使用時は Phase 0 で自動起動されるため、このステップは不要。手動で起動する場合:

```bash
# 自動（推奨）
bash scripts/ensure-chrome-cdp.sh

# 手動
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-cdp-profile
```

### 2. MCP サーバーを設定

`.claude/settings.json`（プロジェクト単位）または `~/.claude/settings.json`（グローバル）に以下を追加:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--cdp-endpoint",
        "http://localhost:9222"
      ]
    },
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--no-usage-statistics",
        "--browser-url=http://127.0.0.1:9222"
      ]
    }
  }
}
```

### 3. dev server を起動

```bash
cd <project>/webapp
npm run dev
```

### 4. Claude Code を起動

```bash
claude
```

MCP 設定は起動時に読み込まれるため、設定変更後は Claude Code の再起動が必要。

## 使い方

### MCP ツールを直接使う

Claude Code に自然言語で指示する:

- 「localhost:3000 を開いて」 → Playwright MCP で操作
- 「スクリーンショットを撮って」 → 画面キャプチャ取得
- 「Console のログを確認して」 → Chrome DevTools MCP でデバッグ情報取得
- 「Network リクエストを見せて」 → API 通信の確認

> **Tip:** Claude Code は効率重視で `curl` 等を使うことがある。ブラウザ操作を明示したい場合は「**Playwright MCP を使って**」と指定する。

### /build-ui スキル

Generator/Evaluator ループで UI を自動的に反復改善するスキル:

```
/build-ui トップページのデザインを改善して
```

1. **Planner** が要件を仕様に展開
2. **Generator** がコードを実装
3. **Evaluator** が Playwright MCP でライブページを検証し、4基準（デザイン品質・独自性・技巧・機能性）で採点
4. 3〜5 サイクル繰り返し、品質を引き上げる

実行中の評価結果は `.build-ui/` ディレクトリにファイルとして蓄積される。

## 実装フェーズ

| Phase | 内容 | 状態 |
|-------|------|------|
| Phase 1 | Playwright MCP セットアップ | 完了 |
| Phase 2 | Chrome DevTools MCP 追加 + ブラウザ共有 | 完了 |
| Phase 3 | スキル化（/check-ui, /debug-frontend, /gen-e2e） | 未着手 |
| Phase 4 | /build-ui（Generator/Evaluator ループ） | 実装済み |

## トラブルシューティング

詳細は [docs/setup-guide.md](docs/setup-guide.md) を参照。

- **MCP が認識されない** → Claude Code を再起動する
- **CDP 接続できない** → `http://localhost:9222/json/version` で Chrome の CDP が有効か確認
- **ポート競合** → `lsof -i :9222` で確認

## 関連資料

- [Playwright MCP](https://github.com/microsoft/playwright-mcp) — Microsoft 公式
- [Chrome DevTools MCP](https://github.com/anthropics/chrome-devtools-mcp) — Google/ChromeDevTools 公式
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — Generator/Evaluator アーキテクチャの参考記事
