---
name: build-ui
description: Build or improve UI with a Generator/Evaluator loop. Planner creates spec, Generator implements code, Evaluator validates via Playwright MCP with 4-criteria scoring. Runs 3-5 iteration cycles. Use when user wants to build UI, improve page design, create a new page, or mentions "build-ui".
---

# /build-ui — Generator/Evaluator UI構築ループ

Planner → Generator ↔ Evaluator の反復ループで UI を構築・改善する。

## 前提条件

- Playwright MCP と Chrome DevTools MCP が設定済み
- Chrome が `--remote-debugging-port=9222` で起動済み
- dev server が起動済み（または起動可能な状態）

## ワークフロー

### Phase 0: 初期化

1. `.build-ui/` ディレクトリと `screenshots/` サブディレクトリを作成
2. dev server が起動しているか確認。未起動なら起動する
3. ユーザーの要件を確認（何を作る/改善するか）

### Phase 1: 企画（Planner）

Agent ツールで Planner サブエージェントを起動する。

プロンプトに含めること:
- [PLANNER.md](PLANNER.md) の全内容
- [HANDOFF.md](HANDOFF.md) の spec.md / contract.md フォーマット
- ユーザーの要件テキスト
- 対象プロジェクトのパス

**完了条件**: `.build-ui/spec.md` と `.build-ui/contract.md` が作成されている

ユーザーに `spec.md` の要約を報告し、方向性を確認する。

### Phase 2: 反復ループ（Generator ↔ Evaluator × 3〜5 サイクル）

各サイクルで以下を実行:

#### Step 2a: Generator

Agent ツールで Generator サブエージェントを起動する。

プロンプトに含めること:
- [GENERATOR.md](GENERATOR.md) の全内容
- [HANDOFF.md](HANDOFF.md) のプロトコル
- 現在のサイクル番号
- `.build-ui/spec.md` の内容
- `.build-ui/contract.md` の内容
- 前サイクルの `.build-ui/evaluation-{n-1}.md` の内容（2回目以降）

**完了条件**: コードが変更され、ビルドエラーがない

#### Step 2b: Evaluator

Agent ツールで Evaluator サブエージェントを起動する。

プロンプトに含めること:
- [EVALUATOR.md](EVALUATOR.md) の全内容
- [HANDOFF.md](HANDOFF.md) のプロトコル
- 現在のサイクル番号
- `.build-ui/spec.md` の内容
- `.build-ui/contract.md` の内容
- 対象ページの URL

**重要**: 過去の evaluation ファイルは渡さない（独立性を保つため）

**完了条件**: `.build-ui/evaluation-{n}.md` が作成されている

#### Step 2c: 判定

`evaluation-{n}.md` のスコアを読み取る:

- **全基準 PASS** → Phase 3 へ進む（早期終了）
- **FAIL あり & サイクル < 5** → contract.md を更新して次のサイクルへ
- **サイクル = 5** → Phase 3 へ進む（上限到達）

ユーザーに各サイクルのスコアを報告する:

```
サイクル {n} 完了:
  デザイン品質: {score}/10 (PASS/FAIL)
  独自性:       {score}/10 (PASS/FAIL)
  技巧:         {score}/10 (PASS/FAIL)
  機能性:       {score}/10 (PASS/FAIL)
```

### Phase 3: 完了報告

ユーザーに最終結果を報告する:
- 全サイクルのスコア推移
- 最終的な変更サマリ
- `.build-ui/` ディレクトリの内容一覧
