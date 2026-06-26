# Copilot BYOK Assistant

언어: [English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | 한국어

Copilot BYOK Assistant는 사용자 지정 BYOK Provider를 통해 GitHub Copilot CLI를 참고하기 위한 Provider 중립적인 Codex Skill입니다. 이 저장소의 산출물은 Codex Skill이며, Copilot CLI는 이 Skill이 호출하는 외부 도구입니다.

이 저장소에는 Provider 인증 정보, 비공개 엔드포인트, 로컬 shell alias, 머신별 경로가 포함되어 있지 않습니다. Provider 설정은 환경 변수 또는 로컬 `.env` 파일로 구성하세요.

## 사용 사례

- **Codex-Copilot 교차 개발**: Codex가 로컬에서 구현이나 리팩터링을 수행한 뒤, BYOK Provider를 통해 Copilot CLI에 계획, diff, 누락된 테스트를 검토하게 할 수 있습니다.
- **이중 에이전트 코드 리뷰**: 한 assistant는 주요 구현을 담당하고, 다른 assistant는 독립 reviewer로 사용해 merge 전에 두 번째 의견을 얻습니다.
- **Provider 비교**: BYOK endpoint나 모델 이름을 바꿔 가며 추론 품질, 코드 리뷰 엄격도, 지연 시간, 비용을 Codex workflow 변경 없이 비교합니다.
- **컴플라이언스와 비공개 라우팅**: 팀이 승인한 Provider, gateway, 네트워크 경로로 Copilot CLI를 호출하고 인증 정보는 저장소 밖에 둡니다.
- **디버깅 지원**: 실패한 명령 출력과 로그를 Copilot CLI에 전달해 근본 원인 가설을 얻고, 제안된 확인 절차를 로컬에서 검증합니다.
- **테스트와 릴리스 계획**: Codex가 구현을 준비한 뒤 누락된 테스트 케이스, 경계 조건, 릴리스 체크, 회귀 위험을 점검합니다.

## 설치

이 저장소를 Codex skills 디렉터리에 clone 합니다:

```bash
mkdir -p ~/.codex/skills
git clone https://github.com/AlbertZhang520/copilot-byok-assistant.git ~/.codex/skills/copilot-byok-assistant
```

## 설정

```bash
cd ~/.codex/skills/copilot-byok-assistant
cp .env.example .env
$EDITOR .env
```

필수 설정:

- `COPILOT_BYOK_BASE_URL`
- `COPILOT_BYOK_MODEL` 또는 `COPILOT_BYOK_MODEL_ID`
- Provider가 API key를 요구하지 않는 경우가 아니라면 `COPILOT_BYOK_API_KEY`

설정을 확인합니다:

```bash
./scripts/run-copilot-byok.sh --check
./scripts/run-copilot-byok.sh --print-config
```

## 사용

```bash
./scripts/run-copilot-byok.sh -p "Review the current git diff for correctness bugs. Do not modify files." --silent
```

Codex에서 Skill로 호출할 수도 있습니다:

```text
Use $copilot-byok-assistant to consult my configured Copilot CLI provider on this implementation plan.
```

## 장시간 작업

다른 code agent가 Copilot CLI 완료 전에 대기를 중단할 수 있는 경우 비동기 모드를 사용하세요:

```bash
run_id=$(./scripts/run-copilot-byok.sh start -- -p "Review this large refactor. Do not modify files." --silent)
./scripts/run-copilot-byok.sh wait "$run_id" --timeout 25
./scripts/run-copilot-byok.sh status "$run_id"
./scripts/run-copilot-byok.sh logs "$run_id" --tail 80
```

비동기 명령:

- `start`: supervisor 아래에서 Copilot CLI를 실행하고 run ID를 출력한 뒤 즉시 반환합니다.
- `status <run_id>`: 상태, 경과 시간, idle 시간, 이유, 종료 코드를 표시합니다.
- `wait <run_id> --timeout N`: 호출자의 대기 예산만큼만 기다립니다. 아직 실행 중이면 `state=running`을 반환하고 Copilot을 종료하지 않습니다.
- `logs <run_id>`: stdout을 표시합니다. `--stderr` 또는 `--events`로 다른 로그를 볼 수 있습니다.
- `cancel <run_id>`: Copilot 프로세스 그룹을 종료하고 run을 cancelled로 표시합니다.
- `list`: 최근 run을 표시합니다.

timeout은 서로 분리되어 있습니다:

- `wait --timeout`: 호출자의 대기 예산일 뿐이며 작업 실패가 아닙니다.
- `start --max-wall`: 전체 작업 실행 시간의 hard cap입니다. 기본값은 `600`초, 종료 코드는 `125`입니다.
- `start --idle-timeout`: 출력이 없는 상태의 timeout입니다. 기본값은 `120`초, 종료 코드는 `124`입니다.

## 보안

- `.env`, API key, Bearer token, 비공개 엔드포인트, 내부 모델 이름을 commit 하지 마세요.
- secret을 과거에 commit 한 적이 있다면 새 저장소를 만들거나 공개 전에 Git 기록을 정리하세요.
- 모델 출력은 참고용으로만 사용하고, 코드를 수정하거나 결론을 보고하기 전에 로컬 증거로 검증하세요.
- `agents/openai.yaml`은 Skill 템플릿이 생성한 Codex UI 메타데이터이며, 이 Skill이 OpenAI Provider 전용이라는 뜻은 아닙니다.

## Release Notes

### 2026-06-26

- 장시간 Copilot CLI 작업을 위해 `start`, `status`, `wait`, `logs`, `cancel`, `list`를 추가했습니다.
- 외부 agent의 대기 예산, 최대 실행 시간, 출력 없음 hang 감지를 독립적으로 처리하는 timeout 제어를 추가했습니다.
- `.copilot-byok/runs/` 아래에 status JSON, stdout/stderr 로그, event 로그를 저장하는 run 디렉터리를 추가했습니다.

## 라이선스

MIT
