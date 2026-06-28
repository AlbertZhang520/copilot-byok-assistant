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

## Agent 协作

当 Copilot 需要和另一个 code agent 协作，而不是只回答一次临时 prompt 时，使用结构化 presets：

```bash
./scripts/pack-context.sh --status --diff --output /tmp/copilot-context.md
./scripts/run-copilot-byok.sh consult review --context /tmp/copilot-context.md --async --wait-timeout 30
```

可用 presets：

- `review`：对 diff 做对抗式审查。
- `plan-critique`：审查实现计划。
- `spec-rederive`：独立复述任务理解。
- `test-design`：生成跨 agent 测试思路。
- `debug-root-cause`：分析失败根因。
- `blast-radius`：评估生产和集成风险。

Preset prompt 会要求 Copilot 返回 `BEGIN_RESULT` / `END_RESULT` 结果块。异步 run 完成后，用 `result <run_id>` 读取提取后的答案。

## 长任务

当其他 code agent 可能在 Copilot CLI 完成前停止等待时，使用异步模式：

```bash
run_id=$(./scripts/run-copilot-byok.sh start -- -p "Review this large refactor. Do not modify files." --silent)
./scripts/run-copilot-byok.sh wait "$run_id" --timeout 25
./scripts/run-copilot-byok.sh status "$run_id"
./scripts/run-copilot-byok.sh logs "$run_id" --tail 80
./scripts/run-copilot-byok.sh result "$run_id"
```

异步命令：

- `start`：由 supervisor 启动 Copilot CLI，打印 run ID，并立即返回。
- `status <run_id>`：查看状态、运行时间、空闲时间、原因和退出码。
- `wait <run_id> --timeout N`：只等待调用方预算。如果任务仍在运行，返回 `state=running`，不会杀掉 Copilot。
- `logs <run_id>`：查看 stdout；用 `--stderr` 或 `--events` 查看其他日志。
- `result <run_id>`：查看提取后的结果块；没有结果块时显示 stdout。
- `cancel <run_id>`：终止 Copilot 进程组，并把任务标记为 cancelled。
- `list`：查看最近任务。

超时语义是分开的：

- `wait --timeout`：只是调用方等待预算，不代表任务失败。
- `start --max-wall`：任务总运行时长硬上限，默认 `600` 秒，退出码 `125`。
- `start --idle-timeout`：无输出超时，默认 `120` 秒，退出码 `124`。

## 安全

- 不要提交 `.env`、API key、Bearer token、私有端点或内部模型名。
- 如果密钥曾经被提交过，请创建全新仓库或清理 Git 历史后再发布。
- 模型输出只作为参考；在修改代码或汇报结论前，用本地证据验证。
- `agents/openai.yaml` 是 Skill 模板生成的 Codex UI 元数据，并不表示该 Skill 只支持 OpenAI Provider。

## Release Notes

### 2026-06-28

- 通过 `consult <preset>` 新增结构化 agent 协作 presets。
- 新增 `scripts/pack-context.sh`，用于生成有边界且经过脱敏的上下文包。
- 新增 `result <run_id>`，并为包含 `BEGIN_RESULT` / `END_RESULT` 的异步 run 持久化 `result.txt`。
- 新增协作协议，覆盖角色分工、调用门槛、finding contract 和分歧裁决规则。

### 2026-06-26

- 新增长任务异步管理：`start`、`status`、`wait`、`logs`、`cancel`、`list`。
- 新增独立超时控制：外层 agent 等待预算、任务总运行时长、无输出卡死检测分别处理。
- 新增 `.copilot-byok/runs/` 任务目录，保存 status JSON、stdout/stderr 日志和事件日志。

## 许可证

MIT
