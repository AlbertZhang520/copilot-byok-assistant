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

## セキュリティ

- `.env`、API key、Bearer token、プライベートエンドポイント、内部モデル名を commit しないでください。
- もし secret を過去に commit したことがある場合は、新しいリポジトリを作成するか、公開前に Git 履歴をクリーンアップしてください。
- モデルの出力は参考情報として扱い、コード変更や結論の報告前にローカルの証拠で検証してください。
- `agents/openai.yaml` は Skill テンプレートが生成する Codex UI メタデータであり、この Skill が OpenAI Provider 専用であることを意味しません。

## ライセンス

MIT
