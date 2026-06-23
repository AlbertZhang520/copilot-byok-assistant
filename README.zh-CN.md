# Copilot BYOK Assistant

语言：[English](README.md) | 简体中文 | [日本語](README.ja.md) | [한국어](README.ko.md)

Copilot BYOK Assistant 是一个面向 Codex 的通用 Skill，用于通过自定义 BYOK Provider 调用 GitHub Copilot CLI。它本身是 Codex Skill；Copilot CLI 是被它调用的外部工具。

仓库不包含 Provider 凭据、私有端点、本地 shell alias 或机器专属路径。请通过环境变量或本地 `.env` 文件配置你的 Provider。

## 使用场景

- **Codex 与 Copilot 交叉开发**：让 Codex 在本地完成实现或重构，再通过 BYOK Provider 调用 Copilot CLI 来审查方案、检查 diff 或补充遗漏测试。
- **双代理代码评审**：一个助手负责主要实现，另一个助手作为独立 reviewer，在合并前给出第二意见。
- **Provider 对比**：切换 BYOK endpoint 或模型名，对比不同 Provider 的推理质量、代码审查严格度、延迟和成本，而不改变 Codex 工作流。
- **合规与私有路由**：通过团队认可的 Provider、网关或网络路径调用 Copilot CLI，同时把凭据保留在仓库外。
- **调试辅助**：把失败命令和输出交给 Copilot CLI 生成根因假设，再由 Codex 或开发者在本地验证。
- **测试与发布规划**：在 Codex 完成实现后，让 Copilot CLI 补充测试用例、边界条件、发布检查项和回归风险。

## 安装

将仓库克隆到 Codex skills 目录：

```bash
mkdir -p ~/.codex/skills
git clone https://github.com/AlbertZhang520/copilot-byok-assistant.git ~/.codex/skills/copilot-byok-assistant
```

## 配置

```bash
cd ~/.codex/skills/copilot-byok-assistant
cp .env.example .env
$EDITOR .env
```

必填配置：

- `COPILOT_BYOK_BASE_URL`
- `COPILOT_BYOK_MODEL` 或 `COPILOT_BYOK_MODEL_ID`
- `COPILOT_BYOK_API_KEY`，除非你的 Provider 不需要 API key

检查配置：

```bash
./scripts/run-copilot-byok.sh --check
./scripts/run-copilot-byok.sh --print-config
```

## 使用

```bash
./scripts/run-copilot-byok.sh -p "Review the current git diff for correctness bugs. Do not modify files." --silent
```

也可以在 Codex 中调用该 Skill：

```text
Use $copilot-byok-assistant to consult my configured Copilot CLI provider on this implementation plan.
```

## 安全

- 不要提交 `.env`、API key、Bearer token、私有端点或内部模型名。
- 如果密钥曾经被提交过，请创建全新仓库或清理 Git 历史后再发布。
- 模型输出只作为参考；在修改代码或汇报结论前，用本地证据验证。
- `agents/openai.yaml` 是 Skill 模板生成的 Codex UI 元数据，并不表示该 Skill 只支持 OpenAI Provider。

## 许可证

MIT
