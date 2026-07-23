# DRM AGENT Skills

[DRM AGENT](https://drm-agent.ai) の会話データを、あなたが普段使っている AI エージェント（Claude Code / Cursor / Codex / Claude Desktop）から分析・活用するための公式スキル集です。

セットアップが終われば、エージェントに話しかけるだけでこんなことができます。

```
ABC商事のカンペ作って            → 過去のやりとりから商談準備ガイドを生成し LINE に配信
昨日の未返信チェックして          → 返信漏れを検知して LINE に通知
今週のダイジェストまとめて        → チャネル横断の週次まとめを LINE に配信
田中さんとの商談サマリー出して     → 決定事項・ネクストアクションを整理して LINE に配信
```

## 目次

- [できること（スキル一覧）](#できることスキル一覧)
- [仕組み](#仕組み)
- [初期セットアップ（3ステップ）](#初期セットアップ3ステップ)
- [使い方](#使い方)
- [応用: 定期実行・スキル自作](#応用-定期実行スキル自作)
- [よくあるつまずき](#よくあるつまずき)

## できること（スキル一覧）

| スキル | 何ができるか | 呼びかけ例 |
| --- | --- | --- |
| [`kanpe`](skills/kanpe/) | 過去のやりとりから商談前カンペ（準備ガイド）を生成し LINE に配信 | 「ABC商事のカンペ作って」 |
| [`meeting-summary`](skills/meeting-summary/) | チャネルの会話を分析し、決定事項・未解決事項・ネクストアクションを LINE に配信 | 「田中さんとの商談サマリー出して」 |
| [`unreplied`](skills/unreplied/) | 未返信・対応漏れメッセージを検知して LINE に通知 | 「未返信チェックして」 |
| [`digest`](skills/digest/) | 複数チャネル横断の日次 / 週次ダイジェストを LINE に配信 | 「今日のダイジェストまとめて」 |
| [`drm-agent-extension-dev`](skills/drm-agent-extension-dev/) | 上記のようなスキルを**自分で開発する**ための開発ガイド | 「拡張スキルを作りたい」 |

## 仕組み

スキル = AI エージェントへの「手順書」（SKILL.md）です。エージェントは DRM AGENT の MCP サーバー経由であなたの組織の会話データにアクセスし、スキルの手順に沿って分析・配信します。

```mermaid
flowchart LR
    A["AI エージェント<br/>(Claude Code / Cursor / Codex)"] -- "スキル (SKILL.md)<br/>が手順を指示" --> A
    A -- "MCP<br/>(API キー認証)" --> B["DRM AGENT<br/>会話データ"]
    B -- "分析結果を配信" --> C["LINE / Discord /<br/>Slack / Chatwork"]
```

必要なものは 2 つだけです。

1. **MCP 接続** — エージェントが DRM AGENT のデータを読めるようにする（API キー）
2. **スキル** — このリポジトリからインストール

## 初期セットアップ（3ステップ）

### Step 1: DRM AGENT で API キーを発行

1. DRM AGENT 管理画面を開く
2. **設定 > MCP連携** に進む（マーケットプレイスの「MCP 連携」が有効な組織で利用できます）
3. ウィザードで API キーを作成し、`mcp_` から始まるキーをコピーする

> 発行時に用途プリセット（**読み取り専用 / 日報分析 / フル / カスタム**）を選べます。送信系スキル（LINE 配信など）を使う場合は送信ツールを含むスコープを選んでください。迷ったら「フル」で問題ありません。

### Step 2: AI エージェントに MCP 接続

エンドポイントは共通で `https://app.drm-agent.ai/api/mcp` です。使っているエージェントの手順だけ実施してください。

<details>
<summary><b>Claude Code</b></summary>

ターミナルで 1 コマンド（`mcp_xxx...` は Step 1 のキーに置き換え）:

```bash
claude mcp add drm-agent \
  --transport http \
  --url "https://app.drm-agent.ai/api/mcp" \
  --header "Authorization: Bearer mcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

`claude mcp list` で `drm-agent` が表示されれば接続完了です。

</details>

<details>
<summary><b>Cursor</b></summary>

プロジェクトの `.cursor/mcp.json`（全プロジェクトで使うなら `~/.cursor/mcp.json`）に追加:

```json
{
  "mcpServers": {
    "drm-agent": {
      "url": "https://app.drm-agent.ai/api/mcp",
      "headers": {
        "Authorization": "Bearer mcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
}
```

Cursor の Settings > MCP で `drm-agent` が緑色になれば接続完了です。

> **注意**: `.cursor/mcp.json` に API キーを書いた場合、このファイルを git にコミットしないでください。

</details>

<details>
<summary><b>Codex</b></summary>

`~/.codex/config.toml` に追加し、API キーは環境変数で渡します:

```toml
[mcp_servers.drm-agent]
url = "https://app.drm-agent.ai/api/mcp"
bearer_token_env_var = "DRM_AGENT_MCP_KEY"
```

```bash
# シェルの設定ファイル（~/.zshrc 等）に追記
export DRM_AGENT_MCP_KEY="mcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

</details>

<details>
<summary><b>Claude Desktop</b></summary>

`claude_desktop_config.json`（Mac: `~/Library/Application Support/Claude/`、Windows: `%APPDATA%\Claude\`）に追加:

```json
{
  "mcpServers": {
    "drm-agent": {
      "url": "https://app.drm-agent.ai/api/mcp",
      "headers": {
        "Authorization": "Bearer mcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
}
```

追加後、Claude Desktop を再起動してください。

</details>

詳細は [公式ドキュメント](https://docs.drm-agent.ai/integrations/mcp-setup) も参照してください。

### Step 3: スキルをインストール

プロジェクトのルートで 1 コマンド。[skills CLI](https://github.com/vercel-labs/skills) がエージェントごとの配置（`.agents/skills/` + Claude Code 用シンボリックリンク）を自動でやってくれます。

```bash
# 対話式でスキルとエージェントを選択
npx skills add line-ec-lea/drm-agent-skills

# よく使うパターン
npx skills add line-ec-lea/drm-agent-skills --all        # 全スキルを一括インストール
npx skills add line-ec-lea/drm-agent-skills -s kanpe -y  # 特定スキルのみ
npx skills add line-ec-lea/drm-agent-skills -g           # プロジェクト単位でなくグローバルに
```

アップデートは `npx skills update`、確認は `npx skills list` です。

<details>
<summary>CLI を使わず手動で配置する場合</summary>

```bash
git clone https://github.com/line-ec-lea/drm-agent-skills.git
mkdir -p .agents/skills
cp -R drm-agent-skills/skills/kanpe .agents/skills/
```

各エージェントが読み込むディレクトリ:

| クライアント | 配置先 |
| --- | --- |
| Claude Code | `.claude/skills/`（プロジェクト）または `~/.claude/skills/`（グローバル） |
| Codex | `.agents/skills/`（プロジェクト）または `~/.agents/skills/`（グローバル） |
| Cursor | `.agents/skills/` / `.cursor/skills/`（`.claude/skills/` も互換で読み込み） |

`.agents/skills/` は Codex と Cursor が共通で読むため、1 か所で済ませたい場合は `.agents/skills/` に置き、Claude Code 用に `.claude/skills/<name>` からシンボリックリンクを張る構成を推奨します。

</details>

### 動作確認

エージェントに話しかけて確認します。

```
DRM AGENT のチャネル一覧を見せて     ← MCP 接続の確認
未返信チェックして                  ← スキル発動の確認
```

チャネル一覧が返ってくれば MCP 接続は成功。スキルの手順（対象チャネルの取得 → 分析 → 送信先の確認）が始まればスキルも有効です。

## 使い方

スキルはキーワードで自動発動します。特別なコマンドは不要で、普通に話しかけるだけです。

| やりたいこと | 話しかけ方の例 |
| --- | --- |
| 商談前の準備 | 「ABC商事のカンペ作って」「明日の○○さんとの商談準備して」 |
| 商談の振り返り | 「ABC商事の直近1週間の商談サマリー出して」 |
| 対応漏れの確認 | 「未返信チェックして」「○○チャネルの返信漏れ見て」 |
| 状況の把握 | 「今日のダイジェストまとめて」「週次まとめを LINE で送って」 |

覚えておきたい動作:

- **送信前に必ず確認されます** — スキルは LINE 等へ配信する前に「この内容をこの宛先に送ってよいか」を確認します。勝手に送信されることはありません
- **期間・対象は自然に指定できます** — 「直近3日」「○○チャネルだけ」のように付け足せば反映されます
- **データはあなたの組織のみ** — API キーは組織単位で発行され、アクセス範囲はその組織のデータに限定されます

## 応用: 定期実行・スキル自作

### 毎日自動で実行したい

「毎朝9時に未返信チェックを LINE に送る」のような無人実行は、Claude Code の headless モード + cron / launchd / GitHub Actions で組めます。設計パターン（送信先の固定・二重実行の防止・失敗時の通知）を [`skills/drm-agent-extension-dev/references/scheduled-execution.md`](skills/drm-agent-extension-dev/references/scheduled-execution.md) にまとめています。

### 自分の業務に合わせたスキルを作りたい

[`drm-agent-extension-dev`](skills/drm-agent-extension-dev/) スキルをインストールして「拡張スキルを作りたい」と話しかけると、課題定義 → データフロー設計 → SKILL.md 作成 → 動作確認までエージェントがガイドします。SKILL.md のテンプレートも同梱しています。

DRM AGENT MCP で使えるツールは全11種です:

- **読み取り**: `list-channels` / `get-channel` / `list-messages` / `get-message` / `search-messages` / `list-connect-users` / `get-connect-user`
- **送信**: `send-line-message` / `send-discord-message` / `send-slack-message` / `send-chatwork-message`

## よくあるつまずき

| 症状 | 対処 |
| --- | --- |
| スキルが発動しない | スキル一覧に出ているか確認（Claude Code: `/` 入力で候補表示、`npx skills list`）。発動キーワード（「カンペ」「未返信」等）を含めて話しかける |
| 「MCP ツールが見つからない」と言われる | Step 2 の接続設定を確認。Claude Code は `claude mcp list`、Cursor は Settings > MCP の接続状態を確認 |
| 401 / 認証エラー | API キーの値・有効期限を管理画面の **設定 > MCP連携** で確認。`Bearer ` の後にキーが正しく入っているか確認 |
| ツールはあるのに実行を拒否される | API キーのスコープ不足の可能性。送信系を使うなら送信ツールを含むスコープでキーを再発行 |
| `allowed-tools` の警告が出る | SKILL.md の `allowed-tools` は Claude Code 専用で、ツール名は MCP の接続名に依存します（`claude mcp add drm-agent` なら `mcp__drm-agent__*`）。接続名が違う場合は書き換えるか行ごと削除してください（他クライアントでは無視されます） |
| データが取れない / 空になる | 対象組織に該当プラットフォームのチャネルがあるか、期間指定が正しいかを確認 |

解決しない場合は [Issue](https://github.com/line-ec-lea/drm-agent-skills/issues) でお知らせください。

## License

[MIT](LICENSE)
