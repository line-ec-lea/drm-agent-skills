---
name: drm-agent-extension-dev
description: SAKIDORI AGENT MCP を使った拡張ツール（digest / kanpe / unreplied / meeting-summary のような MCP 連携スキル）を新規開発・改修するための開発ガイド。「拡張ツール」「拡張スキル」「MCP活用事例を作る」「新しいスキルを作る」等のキーワードで発動。
---

# SAKIDORI AGENT 拡張ツール開発ガイド

SAKIDORI AGENT MCP（全11ツール）を組み合わせ、事業課題を解決する拡張ツール＝スキルを開発するためのメタスキル。成果物は SKILL.md 形式のスキルとして作成し、Claude Code / Codex / Cursor の 3 クライアントすべてから使えるようにする。

## スキルの配置ルール（Claude Code / Codex / Cursor 対応）

実体を `.agents/skills/<name>/` に置き、Claude Code 用に `.claude/skills/<name>` からシンボリックリンクを張る構成を推奨する。手動ミラー（コピー）はドリフトするため禁止。

```bash
# 新規スキル <name> の追加手順
mkdir -p .agents/skills/<name>        # 実体はこちらに作る
ln -s ../../.agents/skills/<name> .claude/skills/<name>
```

各クライアントの読み込み先:

| クライアント | 読み込み先 | 備考 |
| --- | --- | --- |
| Claude Code | `.claude/skills/`（シンボリックリンク追従） | `~/.claude/skills/` でグローバル配置も可 |
| Codex | `$REPO_ROOT/.agents/skills/` ほか階層探索 | シンボリックリンク公式サポート |
| Cursor | `.agents/skills/` / `.cursor/skills/`（互換で `.claude/skills/` も） | 同名スキルは重複登録されない |

クライアント間の互換性で守ること:

- frontmatter の `name` / `description` は全クライアント共通の必須フィールド。**`name` はフォルダ名と一致させる**（Cursor 要件。小文字・数字・ハイフンのみ）
- `allowed-tools` は Claude Code 専用フィールド（他クライアントでは無視される）。書いて問題ないが、依存はしない
- MCP ツール名のプレフィックス（`mcp__claude_ai_SAKIDORI_AGENT__*` 等。旧名「DRM AGENT」で接続した場合は `mcp__claude_ai_DRM_AGENT__*`）はクライアント・接続名依存。本文ではプレフィックスなしのツール名（`list-messages` 等）で手順を書き、`allowed-tools` のみプレフィックス付きにする
- `$ARGUMENTS` は Claude Code のスラッシュコマンド構文。Codex / Cursor では発動時のユーザー発話が引数に相当するため、「引数が読み取れない場合はデフォルト動作」を必ず定義する

## 前提

SAKIDORI AGENT 管理画面の **設定 > MCP連携** で API キーを発行し、利用するクライアントに MCP サーバー（`https://app.drm-agent.ai/api/mcp`、`Authorization: Bearer <key>`）を接続しておく。セットアップ詳細は https://docs.drm-agent.ai/integrations/mcp-setup を参照。

既存スキル `digest` / `kanpe` / `unreplied` / `meeting-summary`（本リポジトリ `skills/` 配下）が house pattern の実例。新規開発の前に最低 1 つ読むこと。

## MCP ツール一覧（組み合わせの部品）

- **読み取り**: `list-channels` / `get-channel` / `list-messages` / `get-message` / `search-messages` / `list-connect-users` / `get-connect-user`（一覧系はカーソルページネーション対応）
- **送信**: `send-line-message` / `send-discord-message` / `send-slack-message` / `send-chatwork-message`
- **外部連携**: Notion・Google Calendar 等はクライアント側で接続済みの別 MCP を併用する（スキル本文に必要ツールを明記）

## 開発ステップ

### Step 1: 課題定義

「**課題 → MCP 活用 → 効果**」の 1 行フォーマットで定義してからコードを書く。誰の・どの業務時間/機会損失を削るのかが言えない企画は作らない。

### Step 2: データフロー設計

3 段で設計する:

1. **入力** — どのチャネル・期間・プラットフォームのメッセージを、どのツールで取るか（期間指定は `list-messages` の `from`/`to`、キーワード起点なら `search-messages`）
2. **分析** — LLM に何をどう判定させるか。**判定基準は必ず SKILL.md に明文化**する（例: unreplied の「パターン1〜3」）。曖昧な「いい感じに要約」は禁止
3. **出力** — 配信先（LINE / Discord / Slack / Chatwork / Notion）とフォーマット。ゼロ件時の挙動・最大メッセージ数も決める

### Step 3: SKILL.md 作成

[references/skill-template.md](references/skill-template.md) をコピーして埋める。house pattern の必須セクション:

- frontmatter（`name` / `description` / `allowed-tools`）— description には機能＋発動キーワードを両方書く
- `## 引数` — `$ARGUMENTS` の受け取り形式とデフォルト
- `## 実行手順` — Step 分割。送信先特定と配信は別 Step にする
- `## LLM出力ポリシー（厳守）` — 具体性の要求・表示媒体前提の制約
- `## 注意事項` — 送信前確認・件数上限・除外条件

### Step 4: 実データで動作確認

対話モードで手動実行し、以下を確認する:

- [ ] 判定精度（誤検知・取り漏らし）が実用レベルか
- [ ] 配信メッセージが媒体（LINE Flex / Discord 等）で正しく表示されるか
- [ ] メッセージ量が多いチャネルでページネーション・件数上限が機能するか

### Step 5: 定期実行化（必要な場合のみ）

無人実行には対話実行と別の設計が要る（送信前確認ができない・二重実行しうる）。[references/scheduled-execution.md](references/scheduled-execution.md) を読んでから設計する。

## 設計原則（全拡張ツール共通）

1. **対話実行では送信前に必ずユーザー確認**（内容と送信先）。無人実行では逆に確認できないので、送信先を引数・設定で固定する
2. **冪等性** — 定期実行されるツールは同一期間の再実行で二重投稿・二重ページ作成しないよう、実行前に既存出力を検索して upsert する
3. **判定基準・優先度の根拠を明文化** — 「高/中/低」を使うなら基準を書く
4. **媒体の表示制約を前提に出力を絞る** — LINE は 1 画面 / 最大 5 メッセージ、長文は Notion 等へ逃してリンクを配信
5. **タイムゾーンは JST 明記** — 「昨日」「直近24時間」の定義を SKILL.md に書く
6. **シークレットをスキルに書かない** — API キー・トークンは MCP クライアント設定側に持たせる
