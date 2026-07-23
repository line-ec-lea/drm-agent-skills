# DRM AGENT Skills

[DRM AGENT](https://drm-agent.ai) の MCP サーバーを活用する公式スキル集です。Claude Code / Codex / Cursor / Claude Desktop などの SKILL.md 対応 AI エージェントから、あなたの組織の会話データを分析・活用できます。

## スキル一覧

| スキル | 何ができるか |
| --- | --- |
| [`kanpe`](skills/kanpe/) | 企業名を指定して過去のやりとりから商談前カンペ（準備ガイド）を生成し、LINE に配信 |
| [`meeting-summary`](skills/meeting-summary/) | 指定チャネルの会話を分析し、決定事項・未解決事項・ネクストアクションを LINE に配信 |
| [`unreplied`](skills/unreplied/) | 未返信・対応漏れメッセージを検知して LINE に通知 |
| [`digest`](skills/digest/) | 複数チャネル横断の日次 / 週次ダイジェストを生成し、LINE に配信 |
| [`drm-agent-extension-dev`](skills/drm-agent-extension-dev/) | 上記のような拡張スキルを**自分で開発する**ための開発ガイド（テンプレート・定期実行パターン付き） |

## セットアップ

### 1. DRM AGENT MCP の API キーを発行

DRM AGENT 管理画面の **設定 > MCP連携** から API キーを作成します（マーケットプレイスの「MCP 連携」が有効な組織で利用できます）。

### 2. MCP クライアントに接続

エンドポイント: `https://app.drm-agent.ai/api/mcp`

**Claude Code**

```bash
claude mcp add drm-agent \
  --transport http \
  --url "https://app.drm-agent.ai/api/mcp" \
  --header "Authorization: Bearer mcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Cursor** — `.cursor/mcp.json`

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

**Codex** — `~/.codex/config.toml` に MCP サーバーとして追加（詳細は Codex のドキュメント参照）

**Claude Desktop** — `claude_desktop_config.json` に上記 Cursor と同形式で追加

詳細は [公式ドキュメント](https://docs.drm-agent.ai/integrations/mcp-setup) を参照してください。

### 3. スキルをインストール

[skills CLI](https://github.com/vercel-labs/skills) でワンコマンドでインストールできます（プロジェクトのルートで実行）。

```bash
# 対話式でスキルとエージェントを選択
npx skills add line-ec-lea/drm-agent-skills

# 特定スキルのみ（例: kanpe）
npx skills add line-ec-lea/drm-agent-skills -s kanpe -y

# 全スキルを全エージェントに一括
npx skills add line-ec-lea/drm-agent-skills --all

# プロジェクト単位でなくグローバル（ユーザーレベル）に入れる場合
npx skills add line-ec-lea/drm-agent-skills -g
```

CLI が実体を `.agents/skills/<name>/`（Cursor / Codex が読む共通配置）に置き、Claude Code 用に `.claude/skills/<name>` のシンボリックリンクを自動作成します。アップデートは `npx skills update` です。

<details>
<summary>手動で配置する場合</summary>

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

### 4. 使ってみる

エージェントに話しかけるだけでスキルが発動します。

```
ABC商事のカンペ作って
昨日の未返信チェックして
今週のダイジェストまとめて
```

## 注意: `allowed-tools` のプレフィックス

各 SKILL.md の frontmatter にある `allowed-tools` は Claude Code 専用フィールドで、ツール名のプレフィックスは **MCP の接続名に依存**します（例: claude.ai コネクタ経由なら `mcp__claude_ai_DRM_AGENT__*`、`claude mcp add drm-agent` なら `mcp__drm-agent__*`）。接続名が異なる場合は書き換えるか、行ごと削除してください（他クライアントでは無視されます）。

## 自分でスキルを開発する

[`drm-agent-extension-dev`](skills/drm-agent-extension-dev/) スキルを配置して「拡張ツールを作りたい」と話しかけると、課題定義 → データフロー設計 → SKILL.md 作成 → 動作確認 → 定期実行化までガイドします。SKILL.md のテンプレートと、cron / GitHub Actions での定期実行パターンも同梱しています。

## DRM AGENT MCP が提供するツール（全11種）

- **読み取り**: `list-channels` / `get-channel` / `list-messages` / `get-message` / `search-messages` / `list-connect-users` / `get-connect-user`
- **送信**: `send-line-message` / `send-discord-message` / `send-slack-message` / `send-chatwork-message`

## License

[MIT](LICENSE)
