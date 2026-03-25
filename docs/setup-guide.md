# Frontend Dev Tools — セットアップガイド

Claude Code で Playwright MCP と Chrome DevTools MCP を使い、ブラウザの操作・観察・デバッグを行うための設定手順。

## 前提条件

- Node.js（npx が使えること）
- Google Chrome（または Chromium）
- Claude Code

## 1. セットアップ

### 1.1 Chrome を CDP ポート付きで起動

両 MCP が同一ブラウザを共有するため、Chrome を Remote Debugging Protocol 付きで起動する。

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-cdp-profile
```

`--user-data-dir` に一時ディレクトリを指定することで、通常の Chrome プロファイルと分離できる。

起動後、`http://localhost:9222/json/version` にアクセスして CDP が有効か確認できる。

### 1.2 MCP サーバー設定

以下の内容を `.claude/settings.json` に配置する。

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

**配置場所:**

| 場所 | パス | 効果 |
|------|------|------|
| プロジェクト単位 | `<project>/.claude/settings.json` | そのプロジェクトでのみ有効 |
| グローバル | `~/.claude/settings.json` | すべてのプロジェクトで有効 |

### 1.3 dev server の起動

対象プロジェクトの dev server を起動する（別ターミナルで）。

```bash
cd <project>/webapp
npm run dev
```

### 1.4 Claude Code の起動

MCP 設定を反映するため、Chrome と dev server を起動した状態で Claude Code を起動（または再起動）する。

```bash
cd <project>
claude
```

## 2. 手動検証手順書

### Phase 1: Playwright MCP

| # | 操作 | 期待結果 |
|---|------|---------|
| 1 | Claude Code に「localhost:3000 を開いて」と指示 | `browser_navigate` ツールが実行され、Chrome にページが表示される |
| 2 | 「アクセシビリティツリーを取得して」と指示 | `browser_snapshot` でページ構造がテキストで返される |
| 3 | 「スクリーンショットを撮って」と指示 | `browser_screenshot` で画面キャプチャが返される |
| 4 | 「〇〇ボタンをクリックして」と指示 | `browser_click` で Chrome 上のボタンが実際にクリックされる |
| 5 | 「テキストフィールドに『テスト』と入力して」と指示 | `browser_type` で Chrome 上のフィールドにテキストが入力される |

### Phase 2: Chrome DevTools MCP

| # | 操作 | 期待結果 |
|---|------|---------|
| 1 | Claude Code に「Console のログを確認して」と指示 | `list_console_messages` でブラウザの Console 出力が返される |
| 2 | 「Network リクエストの一覧を見せて」と指示 | `list_network_requests` でリクエスト一覧が返される |
| 3 | 「`document.title` を evaluate して」と指示 | `evaluate_script` でページタイトルが返される |
| 4 | 「スクリーンショットを撮って」と指示 | `take_screenshot` で画面キャプチャが返される |

### ブラウザ共有の統合検証

| # | 操作 | 期待結果 |
|---|------|---------|
| 1 | 「Playwright MCP で localhost:3000 を開いて」と指示 | Chrome にページが表示される |
| 2 | 続けて「Chrome DevTools MCP で Console ログを確認して」と指示 | 同じページの Console ログが取得できる |
| 3 | 「Playwright MCP でボタンをクリックして、その後 Network リクエストを確認して」と指示 | クリック操作後の API リクエストが Chrome DevTools MCP で確認できる |

**注意:** Claude Code は効率重視で `curl` 等を使うことがある。ブラウザ操作を目視確認したい場合は「**Playwright MCP を使って**」と明示的に指示する。

## 3. グローバル設定への移行

プロジェクト単位で動作確認が取れたら、グローバル設定に移行する。

```bash
# 1. グローバル設定に MCP 設定をコピー
# ~/.claude/settings.json の "mcpServers" に上記設定を追加

# 2. プロジェクト単位の設定から MCP 設定を削除（重複回避）
# <project>/.claude/settings.json から "mcpServers" を削除
```

`~/.claude/settings.json` に既存の設定がある場合は、`mcpServers` キーをマージする。

## 4. トラブルシューティング

### MCP サーバーが Claude Code に認識されない

- Claude Code を再起動したか確認（MCP 設定は起動時に読み込まれる）
- `settings.json` の JSON 構文が正しいか確認
- `npx @playwright/mcp@latest --help` が正常に実行できるか確認

### CDP 接続ができない

- Chrome が `--remote-debugging-port=9222` で起動しているか確認
- `http://localhost:9222/json/version` にアクセスして応答があるか確認
- ポート 9222 が他のプロセスで使われていないか確認: `lsof -i :9222`

### Claude Code が MCP ツールではなく curl を使う

Claude Code は状況に応じて最も効率的な手段を選択する。ブラウザ操作を明示的に行いたい場合：

- 「**Playwright MCP の browser_navigate を使って**ページを開いて」のようにツール名を指定する
- 「**ブラウザ上で**ボタンをクリックして確認したい」のように意図を伝える

### 各 MCP を独立で使いたい（ブラウザ共有なし）

CDP 共有を使わず、各 MCP が独自のブラウザを起動する設定：

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--headed"
      ]
    },
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--no-usage-statistics"
      ]
    }
  }
}
```

この場合、各 MCP は独立したブラウザインスタンスを使用する。
