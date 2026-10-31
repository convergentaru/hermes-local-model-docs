# CURRENT_STATE — локальная AI-инфраструктура

Последнее обновление: 2026-10-31.  
Последний подтверждённый снимок runtime: 2026-10-31.  
Полная точка восстановления: [SESSION_BOOTSTRAP.md](SESSION_BOOTSTRAP.md).

> Ниже описано состояние по последним фактическим тестам, не live-мониторинг. PID и внутренние порты llama-server динамические.

## Архитектура

<badge-placeholder/>

- Одна загруженная модель: `Qwen3.5-9B-Q4_K_M.gguf`.
- Один общий Unsloth `llama-server`.
- Unsloth API wrapper: `127.0.0.1:8888`.
- Два клиента через один endpoint: Hermes (OpenAI Chat Completions) и Claude Code (Anthropic-compatible).
- `--parallel 1`: запросы обслуживаются по одному, с конкуренцией за единственный слот.
- Контекст запуска: 160000.
- Не запускать вторую копию модели и не менять архитектуру без теста и обоснования.

## Последний runtime-снимок

- Unsloth CLI: `2026.10.11`.
- Модель: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- API wrapper: `127.0.0.1:8888`, HTTP 200.
- Внутренний llama-server port: `55831` (динамический в том снимке).
- llama-server PID: `259764` (исторический, не использовать как постоянный).
- Реально переданные аргументы включали `--parallel 1`, `-c 160000`.
- В последней полной проверке обнаружен один llama-server.
- Порт `18434` отсутствовал после отключения Hermes local runtime.
- Hermes Gateway был перезапущен после `hermes config set local_runtime.enabled false` и затем ответил `GATEWAY`.
- Hermes CLI после переключения на `custom:Qwen3.5-9B-Q4_K_M` и новой сессии ответил `ГОТОВО`.
- Claude Code 2.1.286 через `unsloth start claude --no-serve`; `/status` показывал Qwen и base URL `http://127.0.0.1:8888`.
- Прямой OpenAI-compatible тест Unsloth: HTTP 200, тело ответа `ГОТОВО`.

**Статус:** VERIFIED на дату тестов 2026-10-31. Для текущего запуска в новую дату проверять только то, что реально могло измениться.

## Настройки, которые не следует менять без причины

- Контекст: 160000.
- Parallel: 1.
- Unsloth API: 127.0.0.1:8888.
- Модельный файл: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- Hermes `local_runtime.enabled false`, чтобы не поднимать конкурирующий локальный сервер на 18434.
- Claude Code подключать к уже работающему серверу через `--no-serve`.
- Не запускать Unsloth Studio Chat, если задача — только API для Hermes и Claude Code.
- Не запускать Hermes Gateway restart, если конфигурация не менялась и Gateway уже работает.

## Память и контекст Hermes

- Настроенный Hermes Custom context: 160000.
- Это не гарантирует сохранение всей истории в активном контексте: compression может суммировать старые сообщения.
- Точные session telemetry проверять через `/usage`, `/context`, а утраченные прошлые сообщения искать через `session_search`/архив.
- Утверждение о жёстком лимите 70K не подтверждено фактической конфигурацией и не должно повторяться без доказательств.

## Screenlife

Проект и результаты сравнительных тестов Hermes vs Claude Code сохранены в [docs/screenlife/](docs/screenlife/README.md). Последняя публикация результатов — коммит `4efd7fa63a2e8a74f05908ec85694d1eb5f5dae8`.

## Прочие задачи

SystemRescue translation: задача восстановления предыдущей Hermes session и проверки перевода описана в [SESSION_BOOTSTRAP.md](SESSION_BOOTSTRAP.md) и [NEXT_ACTION.md](NEXT_ACTION.md). Не запускать перевод заново до выяснения исхода прежнего задания.

## Журнал и протокол

- [EXPERIMENT_LOG.md](EXPERIMENT_LOG.md)
- [NEXT_ACTION.md](NEXT_ACTION.md)
- [Общий протокол GitHub-first](docs/operations/SHARED-MEMORY-PROTOCOL.md)


---

## Latest superseding state — 2026-10-31

The older state blocks above contain historical snapshots and should not be treated as the current intended architecture. The latest verified configuration is:
- One Unsloth llama-server and one Qwen3.5-9B-Q4_K_M model.
- Unsloth API wrapper `127.0.0.1:8888`.
- Context 160000; `--parallel 1`.
- Hermes Custom OpenAI Chat Completions and Claude Code Anthropic-compatible API use the same Unsloth endpoint.
- Hermes legacy local runtime is disabled; old port 18434 was absent in the last full check.
- Unsloth API, Hermes CLI, Hermes Gateway and Claude Code status passed their respective checks on 2026-10-31.
- Requests are serialized through one slot. PID and internal server port are dynamic.

Hermes/Claude integration research: `docs/integrations/hermes-claude-code.md`. Decision: no additional MCP/ACP/import integration yet; keep agents independent for Screenlife testing.

See `SESSION_BOOTSTRAP.md` for the authoritative recovery summary and `NEXT_ACTION.md` for pending work.


---

## Latest SystemRescue translation recovery update — 2026-10-31

Hermes restored prior session IDs and reports that the remaining eight help files were translated by a subagent in session `20261028_133323_20e490` (`agent_close`). The actual outputs have not yet been located or verified.

The old statement that Qwen3.5-9B has an inherent 70K hard context limit is unsupported. Cumulative session token counters must not be mistaken for the last prompt size. The exact compression-ceiling message indicates a time-bounded compression operation in current Hermes source, not a model context ceiling; the historical Hermes build must still be matched to source.

Canonical detailed audit: https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md


---

## Model upgrade research — candidates only (2026-10-31)

No runtime change. The active/last verified setup remains one Qwen3.5-9B model on one Unsloth llama-server, shared by Hermes and Claude Code, context 160K, `--parallel 1`.

Shortlist for a future controlled evaluation:
- **Qwen3.8-27B UD-Q3_K_XL (13.1 GB)** — current Unsloth recommendation with direct Hermes and Claude Code integration instructions; 27B dense, 256K native context, agentic coding / nested tool calls. Memory fit at 160K has not been tested.
- **Qwen3.6-35B-A3B UD-IQ2_XXS (10.8 GB)** — model used in an earlier setup according to project history; 35B total / 3B active MoE. Local file presence is not verified and the 2-bit quant is a quality compromise.

Use GGUF, not NVFP4, on RTX 3060. Do not delete the working 9B baseline, run two model servers at once, or lower the 160K target without a separate decision. Details: `docs/model-selection/2026-10-31-upgrade-candidates.md`.
