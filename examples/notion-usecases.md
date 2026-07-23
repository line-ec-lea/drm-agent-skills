# Notion MCP / Notion AI 連携ユースケース集

DRM AGENT MCP と [Notion 公式 MCP](https://developers.notion.com/docs/mcp)（`https://mcp.notion.com/mcp`）を同じ AI エージェントに接続すると、**会話データの分析結果を Notion に構造化して蓄積する**ワークフローが組めます。LINE への単発配信と違い、Notion に貯めることで後から検索・集計・Notion AI での活用が可能になります。

すべて「課題 → MCP 活用 → 効果」のフォーマットで整理しています。自組織に合わせてカスタマイズする場合は [`drm-agent-extension-dev`](../skills/drm-agent-extension-dev/) スキルを使ってください。

## 前提

- DRM AGENT MCP を接続済み（[README](../README.md) の初期セットアップ参照）
- Notion MCP を接続済み（Notion 側の接続手順は [Notion 公式ドキュメント](https://developers.notion.com/docs/mcp) 参照）

## ユースケース 1: 成果報告デイリーレポート

> 実装済みサンプル: [`skills/notion-daily-report`](../skills/notion-daily-report/) ／ コピペ導入手順・定期実行ファイル一式: [notion-daily-report クイックスタート](notion-daily-report/)

- **課題**: メンバー・受講生の成果報告が複数チャネルに散在し、拾い漏れる。称賛やフォローが遅れる
- **MCP 活用**: 前日（JST）の全チャネルの会話から成果報告を抽出 → Notion データベースに日次ページとして蓄積 → Discord にサマリーと Notion リンクを通知
- **効果**: 成果の見える化と称賛・フォローの即時化。月次の振り返りは Notion 側で集計するだけ

データフロー:

```
list-channels + list-messages（JST 前日分）
  → LLM が成果報告を判定・抽出（誰が・何を・数値）
  → Notion DB を日付で検索し upsert（二重実行しても重複しない）
  → send-discord-message でサマリー + Notion URL を通知
```

## ユースケース 2: 商談議事録の Notion 蓄積

- **課題**: 商談サマリーを LINE で受け取っても流れてしまい、過去の経緯を辿れない
- **MCP 活用**: [`meeting-summary`](../skills/meeting-summary/) の出力先を LINE から Notion に変更（または併用）。商談 DB に「日付・企業名・決定事項・未解決事項・ネクストアクション」のページを作成
- **効果**: 企業ごとの商談履歴が Notion 上で時系列に揃い、次回の [`kanpe`](../skills/kanpe/)（商談前カンペ）の精度も上がる

カスタマイズのポイント: meeting-summary の Step 5（LINE 配信）を「Notion の商談 DB にページ作成 → 作成した URL を LINE で通知」に置き換えるだけで成立します。

## ユースケース 3: 顧客カルテ・会員カルテの自動生成

- **課題**: 顧客/受講生ごとの状況（背景・目標・進捗・懸念）が担当者の頭の中にしかなく、引き継ぎや横断把握ができない
- **MCP 活用**: チャネル単位で会話履歴を分析し、Notion に 1 顧客 = 1 ページの「カルテ」を生成。定期実行で新しい会話を差分反映して更新し続ける
- **効果**: 誰でも最新のカルテを見てから対応に入れる。担当交代・チーム対応がスムーズに

データフロー:

```
list-channels（対象グループ）
  → 各チャネルの list-messages（前回更新以降）
  → LLM が カルテ項目（基本情報 / 目標 / 直近の状況 / 懸念 / 次のアクション）を更新
  → Notion のカルテ DB を顧客名で検索し upsert
```

設計の注意: カルテは「上書き」でなく**セクション単位の追記・更新**にする（履歴が消えないように、更新日と根拠になった会話期間をページに記録する）。

## ユースケース 4: FAQ・ナレッジベースの自動構築

- **課題**: 同じ質問への回答を毎回書いている。良い回答例がチャネルに埋もれている
- **MCP 活用**: `search-messages` / `list-messages` で質問・回答ペアを抽出し、頻出トピックごとに Notion の FAQ DB へ登録。既存 FAQ と重複するものは統合
- **効果**: 対応品質の均一化と新人オンボーディングの高速化。FAQ が「実際に効いた回答」ベースで育つ

## ユースケース 5: Notion AI との組み合わせ（蓄積後の活用）

ユースケース 1〜4 で会話データを Notion に構造化して蓄積すると、その先は **Notion AI がそのまま社内ナレッジとして使えます**。役割分担は次の通りです。

| 役割 | 担当 |
| --- | --- |
| 会話データの抽出・判定・構造化・Notion への蓄積 | AI エージェント + DRM AGENT MCP + Notion MCP（このリポジトリのスキル） |
| 蓄積されたデータの横断検索・要約・Q&A | Notion AI |

例:

- 成果報告 DB に対して Notion AI に「**今月もっとも成果を出したメンバーは？**」と質問する
- カルテ DB を Notion AI で横断検索し「**◯◯という課題を抱えている顧客の一覧**」を出す
- 商談 DB から Notion AI に「**失注案件に共通する懸念点をまとめて**」と分析させる

ポイント: Notion AI はワークスペース内のデータにしかアクセスできないため、**DRM AGENT の会話データを Notion に流し込む部分**が価値の源泉になります。蓄積スキーマ（DB のプロパティ設計）を Notion AI で聞きたい質問から逆算して決めるのがコツです。

## 定期実行するには

これらのユースケースは定期実行（毎朝・毎週）と組み合わせて真価を発揮します。無人実行の設計（送信先の固定・冪等性・失敗時通知）は [`skills/drm-agent-extension-dev/references/scheduled-execution.md`](../skills/drm-agent-extension-dev/references/scheduled-execution.md) を参照してください。
