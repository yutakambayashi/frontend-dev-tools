# PRD: Frontend Dev Tools — MCP セットアップ (Phase 1+2)

## Problem Statement

Claude Codeはコードの読み書きには優れているが、フロントエンドの「見た目」や「ブラウザ上の動作」を確認する手段がない。UIが崩れていても気づけず、ユーザーから「動かない」と言われてもConsoleエラーやNetworkリクエストを確認できないため、対応が遅れる。開発者が毎回手動でブラウザを開いて確認し、状況をClaude Codeに伝える必要がある。

## Solution

Playwright MCP（`@playwright/mcp`）と Chrome DevTools MCP（`chrome-devtools-mcp`）を Claude Code に統合し、ブラウザの操作・観察・デバッグ情報取得を可能にする。

両MCPは、ユーザーが `--remote-debugging-port=9222` 付きで起動したChrome/Chromiumに CDP 経由で接続し、同一ブラウザインスタンスを共有する。これにより、Playwright MCPで操作した画面のConsoleログやNetworkリクエストを Chrome DevTools MCPで即座に確認できる。

## User Stories

1. 開発者として、Claude Codeからブラウザでページを開いてスクリーンショットを取得したい。コード変更後のUI確認を手動で行う手間を省くため
2. 開発者として、Claude Codeからページのアクセシビリティツリーを取得したい。DOMの構造をトークン効率よく把握するため
3. 開発者として、Claude Codeからブラウザ上のボタンクリックやフォーム入力を実行したい。UIの動作確認を自動化するため
4. 開発者として、Claude CodeからブラウザのConsoleエラー・ログを確認したい。ランタイムエラーの原因を特定するため
5. 開発者として、Claude CodeからNetworkリクエストの一覧と詳細を確認したい。APIの呼び出し状況やエラーレスポンスを把握するため
6. 開発者として、Claude CodeからPerformanceトレースを取得したい。パフォーマンス問題の原因を分析するため
7. 開発者として、Playwright MCPとChrome DevTools MCPが同じブラウザを共有してほしい。操作した画面のデバッグ情報をそのまま取得するため
8. 開発者として、dev serverが起動済みならそのまま接続し、未起動なら自動起動してほしい。セットアップの手間を最小限にするため
9. 開発者として、MCP設定をまずプロジェクト単位で試し、うまくいったらグローバルに移行したい。段階的に導入するため
10. 開発者として、デバッグ時はブラウザをGUI表示で確認したい。自分の目でも画面を見ながらClaude Codeと協調作業するため
11. 開発者として、Claude CodeからJavaScriptを評価実行したい。ページの状態を動的に検査するため
12. 開発者として、Claude Codeからタブの作成・切替・閉じを行いたい。複数ページにまたがるワークフローを確認するため
13. 開発者として、Claude CodeからLighthouse監査を実行したい。アクセシビリティやパフォーマンスの問題を検出するため
14. 開発者として、ブラウザ共有が技術的に困難な場合でも、各MCPが独立で動作してほしい。一方のMCPの問題で全体が使えなくなることを避けるため

## Implementation Decisions

### MCP サーバー選定

| MCP | パッケージ | 選定理由 |
|-----|-----------|---------|
| Playwright MCP | `@playwright/mcp` (Microsoft公式) | スナップショットモード（アクセシビリティツリー）がLLM向けに最適。CDP接続対応。最も豊富な操作ツール群 |
| Chrome DevTools MCP | `chrome-devtools-mcp` (Google/ChromeDevTools公式) | 29ツール。Console/Network/Performance/Lighthouse完備。CDP接続対応 |

### ブラウザ共有アーキテクチャ

1. ユーザーがChrome/Chromiumを `--remote-debugging-port=9222` 付きで起動
2. Playwright MCPが `--cdp-endpoint http://localhost:9222` で接続
3. Chrome DevTools MCPが `--browser-url=http://127.0.0.1:9222` で接続
4. 両MCPが同一ブラウザインスタンスを操作・監視

フォールバック: ブラウザ共有が技術的に困難な場合、各MCPが独立にブラウザを起動する構成も許容する。

### 設定ファイル構成

**Phase 1（Playwright MCP のみ）:**

`.claude/settings.json` にPlaywright MCPサーバーを追加。まず単独での動作を確認する。

**Phase 2（Chrome DevTools MCP 追加 + ブラウザ共有）:**

同ファイルに Chrome DevTools MCPを追加し、CDP接続でブラウザ共有を構成する。

**グローバル移行:**

プロジェクト単位で動作確認後、`~/.claude/settings.json` にMCP設定を移行し、どのプロジェクトでも利用可能にする。

### dev server 管理

- dev server（`next dev`）が `localhost:3000` で起動済みならそのまま接続
- 未起動の場合は Claude Code がバックグラウンドで起動
- 対象プロジェクト: `slide_sample_choose/webapp`（Next.js 16 + React 19）

### Playwright MCP の動作モード

- **スナップショットモード（デフォルト）**: アクセシビリティツリーベース。トークン効率が高く、要素の特定が安定
- **ビジョンモード（`--vision`）**: スクリーンショットベース。視覚的な確認が必要な場合に使用
- **ブラウザ表示**: デバッグ時は `--headed` でGUI表示

### 成果物

1. `.claude/settings.json` — MCP サーバー設定
2. 手動検証手順書 — 各MCP の動作確認チェックリスト
3. セットアップガイド — ブラウザ起動手順、設定方法のドキュメント

## Testing Decisions

自動テストの対象ではないため（成果物は設定ファイルとドキュメント）、手動検証手順書で品質を担保する。

### 手動検証チェックリスト

**Phase 1: Playwright MCP**
- [ ] MCP サーバーが Claude Code で認識される
- [ ] `browser_navigate` で localhost:3000 にアクセスできる
- [ ] `browser_snapshot` でアクセシビリティツリーが取得できる
- [ ] `browser_screenshot` でスクリーンショットが取得できる
- [ ] `browser_click` / `browser_type` で要素操作ができる

**Phase 2: Chrome DevTools MCP**
- [ ] MCP サーバーが Claude Code で認識される
- [ ] `list_console_messages` でConsoleログが取得できる
- [ ] `list_network_requests` でNetworkリクエストが確認できる
- [ ] `evaluate_script` でJavaScript実行ができる
- [ ] `take_screenshot` でスクリーンショットが取得できる

**ブラウザ共有**
- [ ] Chrome を `--remote-debugging-port=9222` で起動できる
- [ ] 両MCPが同一ブラウザに接続できる
- [ ] Playwright MCP で操作した結果が Chrome DevTools MCP で確認できる（例: ボタンクリック後のConsoleログ）

## Out of Scope

- **スキルの実装**（`/check-ui`, `/debug-frontend`, `/gen-e2e`）— Phase 3 で別途対応
- **スキルのインターフェース設計** — Phase 3 で別途対応
- **Generator/Evaluator アーキテクチャ** — Phase 4 で別途対応
- **CI/CD 統合** — 開発環境のローカル利用に限定
- **ヘッドレスモードでのテスト自動化** — Phase 3 以降
- **Next.js 以外のフレームワーク対応** — 現時点では slide_sample_choose を対象とする
- **セキュリティ対策** — 開発環境のため特に制限なし

## Further Notes

- Playwright MCP のスナップショットモードは、スクリーンショットよりもトークン消費が少なく、LLMエージェントとの相性が良い。ビジョンモードは視覚的な確認が必要な場合の補助として使う
- Chrome DevTools MCP の `--slim` モードでは3ツール（navigate, evaluate, screenshot）に限定できるが、今回はフル機能を使う
- `chrome-devtools-mcp` はテレメトリを送信するため、`--no-usage-statistics` の付与を検討する
- ブラウザ共有が安定しない場合、Phase 2 のフォールバックとして各MCPが独立にブラウザを起動する構成に切り替える。この場合でも各MCPの機能は個別に利用可能
