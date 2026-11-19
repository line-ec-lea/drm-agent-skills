# notion-daily-report クイックスタート（コピペで導入）

成果報告デイリーレポート（[skills/notion-daily-report](../../skills/notion-daily-report/)）を最短で動かす手順です。以下のブロックをコピペするだけで、対話利用（5分）→ 毎朝の自動実行まで到達できます。

## Part 1: 対話で使えるようにする（5分）

### 1. MCP を 2 つ接続（Claude Code の場合）

`mcp_xxx...` は SAKIDORI AGENT 管理画面（**設定 > MCP連携**）で発行したキーに置き換えてください。

```bash
# SAKIDORI AGENT MCP
claude mcp add drm-agent \
  --transport http \
  --url "https://app.drm-agent.ai/api/mcp" \
  --header "Authorization: Bearer mcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Notion 公式 MCP（ブラウザで Notion ログインを求められます）
claude mcp add notion --transport http https://mcp.notion.com/mcp
```

接続確認: `claude mcp list` で `drm-agent` と `notion` が表示されれば OK。

<details>
<summary>Cursor の場合（.cursor/mcp.json にコピペ）</summary>

```json
{
  "mcpServers": {
    "drm-agent": {
      "url": "https://app.drm-agent.ai/api/mcp",
      "headers": {
        "Authorization": "Bearer mcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    },
    "notion": {
      "url": "https://mcp.notion.com/mcp"
    }
  }
}
```

Settings > MCP で notion の「Login」を実行してください。

</details>

### 2. スキルをインストール

```bash
npx skills add line-ec-lea/drm-agent-skills -s notion-daily-report -y
```

### 3. 初回実行（セットアップは自動で走る）

エージェントにこう話しかけるだけです:

```
成果報告レポート作って
```

初回はスキルが自動で以下を行います。手作業の事前準備は不要です。

1. Notion に「成果報告デイリーレポート」DB がなければ**自動作成**
2. Discord の送信先チャネルを候補から**選択させてくれる**
3. 確定した設定を SKILL.md に**書き戻し**（次回から確認なし）
4. 昨日の成果報告を抽出 → Notion 保存 → 内容確認のうえ Discord 通知

## Part 2: 毎朝自動で実行する

このフォルダの 3 ファイルをコピーして使います。**ローカル（Mac + cron）** か **GitHub Actions** のどちらかを選んでください。

### 共通: 必要なシークレット

| 変数 | 取得場所 |
| --- | --- |
| `ANTHROPIC_API_KEY` | [Anthropic Console](https://console.anthropic.com/)（Claude Code の従量 API キー） |
| `DRM_AGENT_MCP_KEY` | SAKIDORI AGENT 管理画面 > 設定 > MCP連携 |
| `NOTION_TOKEN` | [Notion インテグレーション](https://www.notion.so/my-integrations)（Internal Integration Token。対象 DB をインテグレーションに共有すること） |
| `DISCORD_CHANNEL_ID` | SAKIDORI AGENT の `list-channels` で確認したチャネル ID（Part 1 の初回実行で SKILL.md に記録された値） |

> 無人実行では Notion 公式 MCP（OAuth）ではなく、トークン認証の `@notionhq/notion-mcp-server` を使います（[mcp.json](mcp.json) に設定済み）。

### A. ローカル（Mac / Linux + cron）

```bash
# 1. このフォルダを作業ディレクトリにコピー
mkdir -p ~/drm-agent-jobs && cd ~/drm-agent-jobs
curl -sL https://raw.githubusercontent.com/line-ec-lea/drm-agent-skills/main/examples/notion-daily-report/mcp.json -o mcp.json
curl -sL https://raw.githubusercontent.com/line-ec-lea/drm-agent-skills/main/examples/notion-daily-report/run.sh -o run.sh
chmod +x run.sh

# 2. スキルをこのディレクトリにインストール
npx skills add line-ec-lea/drm-agent-skills -s notion-daily-report -a claude-code -y

# 3. シークレットを環境変数ファイルに保存（gitに入れない）
cat > .env <<'EOF'
export ANTHROPIC_API_KEY="sk-ant-..."
export DRM_AGENT_MCP_KEY="mcp_..."
export NOTION_TOKEN="ntn_..."
export DISCORD_CHANNEL_ID="123456789012345678"
EOF
chmod 600 .env

# 4. 手動で一度テスト実行
./run.sh

# 5. 問題なければ cron 登録（毎朝9時 JST）
crontab -e
# 以下を追記:
# 0 9 * * * cd ~/drm-agent-jobs && ./run.sh >> report.log 2>&1
```

### B. GitHub Actions

1. 自分のプライベートリポジトリを用意し、[github-actions.yml](github-actions.yml) を `.github/workflows/notion-daily-report.yml` にコピー、[mcp.json](mcp.json) を `mcp.json` にコピー
2. リポジトリの **Settings > Secrets and variables > Actions** に登録:
   - Secrets: `ANTHROPIC_API_KEY` / `DRM_AGENT_MCP_KEY` / `NOTION_TOKEN`
   - Variables: `DISCORD_CHANNEL_ID`
3. **Actions タブ > Notion Daily Report > Run workflow** で手動実行してテスト
4. 以降は毎朝 9:00 JST に自動実行されます（時刻は yml の `cron` を編集）

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| Notion のツールが見つからない | Part 1-1 の notion 接続と Login を確認。無人実行では `NOTION_TOKEN` の設定と、対象 DB がインテグレーションに共有されているかを確認 |
| Notion DB に書き込めない | インテグレーションの権限（Insert/Update content）と DB 共有を確認 |
| Discord に届かない | `DISCORD_CHANNEL_ID` が SAKIDORI AGENT に連携済みのチャネルか確認（`list-channels` で一覧表示） |
| 二重に投稿される | スキルは日付 upsert で冪等化済み。cron と GitHub Actions の併用など多重スケジュールになっていないか確認 |
