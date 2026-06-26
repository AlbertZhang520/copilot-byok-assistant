# Copilot BYOK Assistant

言語：[English](README.md) | [简体中文](README.zh-CN.md) | 日本語 | [한국어](README.ko.md)

Copilot BYOK Assistant は、カスタム BYOK Provider 経由で GitHub Copilot CLI を参照するための、Provider 非依存の Codex Skill です。これは Codex Skill であり、Copilot CLI はこの Skill から呼び出される外部ツールです。

このリポジトリには、Provider の認証情報、プライベートエンドポイント、ローカル shell alias、マシン固有のパスは含まれていません。Provider は環境変数またはローカルの `.env` ファイルで設定してください。

## ユースケース

- **Codex と Copilot のクロス開発**：Codex がローカルで実装やリファクタリングを行い、その後 BYOK Provider 経由の Copilot CLI に計画、diff、または不足しているテストをレビューさせます。
- **二重エージェントレビュー**：一方のアシスタントを主な実装担当にし、もう一方を独立した reviewer として使い、merge 前に第二意見を得ます。
- **Provider 比較**：BYOK endpoint やモデル名を切り替えて、推論品質、コードレビューの厳しさ、レイテンシ、コストを Codex ワークフローを変えずに比較します。
- **コンプライアンスとプライベートルーティング**：チームが承認した Provider、gateway、またはネットワーク経路で Copilot CLI を使い、認証情報はリポジトリ外に保持します。
- **デバッグ支援**：失敗したコマンド出力を Copilot CLI に渡して根本原因の仮説を得て、その確認手順をローカルで検証します。
- **テストとリリース計画**：Codex が実装を準備した後、不足しているテストケース、境界条件、リリースチェック、回帰リスクを洗い出します。

## インストール

このリポジトリを Codex skills ディレクトリに clone します：

```bash
mkdir -p ~/.codex/skills
git clone https://github.com/AlbertZhang520/copilot-byok-assistant.git ~/.codex/skills/copilot-byok-assistant
```

## 設定

```bash
cd ~/.codex/skills/copilot-byok-assistant
cp .env.example .env
$EDITOR .env
```

必須設定：

- `COPILOT_BYOK_BASE_URL`
- `COPILOT_BYOK_MODEL` または `COPILOT_BYOK_MODEL_ID`
- Provider が API key を不要としない限り、`COPILOT_BYOK_API_KEY`

設定を確認します：

```bash
./scripts/run-copilot-byok.sh --check
./scripts/run-copilot-byok.sh --print-config
```

## 使い方

```bash
./scripts/run-copilot-byok.sh -p "Review the current git diff for correctness bugs. Do not modify files." --silent
```

Codex から Skill として呼び出すこともできます：

```text
Use $copilot-byok-assistant to consult my configured Copilot CLI provider on this implementation plan.
```

## 長時間タスク

他の code agent が Copilot CLI の完了前に待機をやめる可能性がある場合は、非同期モードを使います：

```bash
run_id=$(./scripts/run-copilot-byok.sh start -- -p "Review this large refactor. Do not modify files." --silent)
./scripts/run-copilot-byok.sh wait "$run_id" --timeout 25
./scripts/run-copilot-byok.sh status "$run_id"
./scripts/run-copilot-byok.sh logs "$run_id" --tail 80
```

非同期コマンド：

- `start`：supervisor の下で Copilot CLI を起動し、run ID を出力してすぐに戻ります。
- `status <run_id>`：状態、経過時間、アイドル時間、理由、終了コードを表示します。
- `wait <run_id> --timeout N`：呼び出し側の待機予算だけ待ちます。実行中なら `state=running` を返し、Copilot は終了しません。
- `logs <run_id>`：stdout を表示します。`--stderr` または `--events` で他のログを確認できます。
- `cancel <run_id>`：Copilot のプロセスグループを終了し、run を cancelled として記録します。
- `list`：最近の run を表示します。

タイムアウトは分離されています：

- `wait --timeout`：呼び出し側の待機予算だけであり、タスク失敗ではありません。
- `start --max-wall`：タスク全体の実行時間上限です。デフォルトは `600` 秒、終了コードは `125` です。
- `start --idle-timeout`：出力がない状態のタイムアウトです。デフォルトは `120` 秒、終了コードは `124` です。

## セキュリティ

- `.env`、API key、Bearer token、プライベートエンドポイント、内部モデル名を commit しないでください。
- もし secret を過去に commit したことがある場合は、新しいリポジトリを作成するか、公開前に Git 履歴をクリーンアップしてください。
- モデルの出力は参考情報として扱い、コード変更や結論の報告前にローカルの証拠で検証してください。
- `agents/openai.yaml` は Skill テンプレートが生成する Codex UI メタデータであり、この Skill が OpenAI Provider 専用であることを意味しません。

## Release Notes

### 2026-06-26

- 長時間の Copilot CLI タスク向けに、`start`、`status`、`wait`、`logs`、`cancel`、`list` を追加しました。
- 外側の agent の待機予算、最大実行時間、無出力ハング検出を独立して扱うタイムアウト制御を追加しました。
- `.copilot-byok/runs/` に status JSON、stdout/stderr ログ、イベントログを保存する run ディレクトリを追加しました。

## ライセンス

MIT
