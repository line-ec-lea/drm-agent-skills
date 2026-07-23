# 定期実行パターン

拡張ツールを無人で定期実行する場合の実行基盤の選択肢と、無人実行特有の設計上の注意。

## 実行基盤の選択肢

Cursor / Claude Desktop の対話 UI 自体には cron 機能がないため、定期実行は以下のいずれかで行う。

### 1. Claude Code headless + OS スケジューラ（推奨・最小構成）

`claude -p` を launchd（Mac）/ cron から叩く。MCP 設定はプロジェクトの `.mcp.json` を参照させる。

```bash
claude -p "/digest daily" \
  --mcp-config /path/to/project/.mcp.json \
  --allowedTools "mcp__drm-agent__*" \
  --output-format json
```

- 長所: ローカル完結・スキルをそのまま使える・追加コスト無し
- 短所: マシンが起動している必要がある。launchd の plist 管理が必要

### 2. Claude Code scheduled tasks / cloud routine

Claude Code の schedule 機能でクラウド実行。ローカルマシン不要だが、MCP サーバーへの認証（API キー）をクラウド側セッションで解決できることが条件。

### 3. GitHub Actions cron

`schedule:` トリガーで `claude -p` を実行するワークフロー。API キー類は GitHub Secrets に置く。

- 長所: マシン不要・実行ログが残る・チームで共有できる
- 短所: Anthropic API キーの Secrets 管理が必要

### 4. Cursor から実行したい場合

Cursor 自体は定期実行を持たないため、実体は cursor-agent CLI（または上記 1〜3）を OS スケジューラから起動する構成になる。「Cursor で作ったスキル運用をそのまま自動化したい」場合も、無人実行の実体は headless CLI である点をユーザーに説明すること。

## 無人実行の設計チェック

対話実行との最大の違いは **送信前のユーザー確認ができない** こと。以下を必ず満たす。

1. **送信先の固定** — `list-connect-users` から動的に選ばず、チャネル ID / ユーザー ID を引数か SKILL.md 内の定数として固定する
2. **冪等性** — 同一期間の再実行（リトライ・二重起動）で二重投稿しない。実行冒頭に既存出力（Notion の同日付ページ、直近の自分の投稿等）を検索し、存在すれば更新 or スキップ
3. **期間の決定性** — 「昨日」= JST の前日 00:00〜24:00 のように、実行時刻に依存しない期間定義にする
4. **失敗時の通知** — 取得 0 件と実行失敗を区別する。失敗した場合も Discord 等へエラー通知を送る（沈黙させない）
5. **出力の縮退** — 件数が想定超過した場合の上限と縮退動作（上位 N 件＋残数報告）を決めておく
6. **シークレット** — DRM AGENT API キー・Notion トークン等は `.mcp.json`（gitignore 対象）/ launchd 環境変数 / GitHub Secrets に置く。SKILL.md・ワークフロー YAML に直書きしない

## Notion 連携の冪等パターン

日次レポートを Notion に蓄積する場合の推奨手順:

1. レポート用 DB を用意（プロパティ例: 日付 / 対象期間 / 報告者数 / ステータス）
2. 実行冒頭に対象日付で DB を検索
3. 既存ページあり → 上書き更新（または処理スキップ）、なし → 新規ページ作成
4. Discord への通知には作成/更新した Notion ページの URL を含める
