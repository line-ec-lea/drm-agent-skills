#!/usr/bin/env bash
# notion-daily-report 無人実行スクリプト
# 必要な環境変数: ANTHROPIC_API_KEY / DRM_AGENT_MCP_KEY / NOTION_TOKEN / DISCORD_CHANNEL_ID
# 同ディレクトリに mcp.json と、npx skills add でインストール済みのスキルがあること
set -euo pipefail
cd "$(dirname "$0")"

# .env があれば読み込む
[ -f .env ] && source .env

: "${ANTHROPIC_API_KEY:?ANTHROPIC_API_KEY が未設定です}"
: "${DRM_AGENT_MCP_KEY:?DRM_AGENT_MCP_KEY が未設定です}"
: "${NOTION_TOKEN:?NOTION_TOKEN が未設定です}"
: "${DISCORD_CHANNEL_ID:?DISCORD_CHANNEL_ID が未設定です}"

claude -p "notion-daily-report スキルを定期実行モードで実行して。昨日（JST）の成果報告レポートを Notion に upsert し、Discord チャネル ID ${DISCORD_CHANNEL_ID} に通知まで完了させること。確認は不要。失敗した場合はエラー内容を同じチャネルに通知すること。" \
  --mcp-config mcp.json \
  --allowedTools "mcp__drm-agent__*,mcp__notion__*,Read" \
  --output-format json \
  --max-turns 50
