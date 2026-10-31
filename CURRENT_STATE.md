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


---

## User priority update — audio work before larger model (2026-10-31)

The user has explicitly chosen to work on audio/voice first and postpone downloading a larger model until afterwards.

No model change or download is approved now. The current known-good Qwen3.5-9B setup remains the baseline; context 160K and one shared llama-server remain unchanged.

The 27B candidate is considered a memory-fit risk on RTX 3060 12 GB VRAM + approximately 12 GB system RAM, especially with a 160K context. A 13.1 GB GGUF weight file does not include KV cache and runtime overhead. Reassess only after audio work is complete, then inspect available memory and the existing local Qwen3.6-35B-A3B file before considering a download.

Voice work notes: `docs/voice/qwen3-asr-and-hermes-voice.md`. Current next-step ordering: `NEXT_ACTION.md`.


---

## Latest SystemRescue artifact report — 2026-10-31

Hermes reports two files in `/home/oleg/fcm-opencode-test`, with sizes and SHA-256 listed in the canonical PC Rescue audit. The original and translated paths are reported as identical; preserve the files before any editing because the originals may have been overwritten in place. The remaining six outputs were not located in that directory; task transcript filenames are still needed. Filesystem presence and hashes have not been independently verified in this chat.

Latest reported context data: Hermes configured window 131072; auto-compress threshold 100000; historical llama-server `-c 160000`; subagent last prompt 32964. These are distinct settings/measurements. Cache-write counters do not establish compression count. The SSH/QEMU session still has a timestamp discrepancy (session ID 20261024 but reported year 2024).

Detailed record: https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md


## Benchmarking standard

All future model comparisons must follow `docs/model-selection/BENCHMARK-PROTOCOL.md`. Separate capability scores from actual local inference speed and agent workflow quality. No model upgrade is decided from parameter count or file size alone.


---

## Runtime checkpoint — 2026-10-31 (latest user-provided evidence; supersedes earlier port snapshot)

### Unsloth / Qwen — VERIFIED
The user launched the existing local model through the Unsloth CLI:

```bash
unsloth run \
  --model "/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf" \
  --context-length 160000 \
  --gpu-memory-mode manual \
  --parallel 1 \
  --port 8888 \
  --host 127.0.0.1 \
  --disable-tools
```

Observed:
- Unsloth CLI version: `2026.10.11`.
- Public client endpoint: `http://127.0.0.1:8888/v1`.
- Internal llama-server port in this run: `53815` (dynamic; do not hardcode).
- Model loaded and server reported ready.
- `GET /v1/models`: HTTP 200; Qwen3.5-9B-Q4_K_M reported loaded; configured context 160000; model native/max context reported as 262144.
- A real `POST /v1/chat/completions` returned HTTP 200 and the expected Russian response. This verifies the Unsloth API path, not yet the Hermes Gateway path.
- `--disable-tools` was passed to the server. Agent-side tools must be tested independently; do not assume this flag disables or enables client-side Hermes/Claude tools.

### Existing Hermes configuration — OBSERVED
- `model.provider: custom`.
- Base URL: `http://127.0.0.1:8888/v1`.
- Model ID: `Qwen3.5-9B-Q4_K_M`.
- API mode: `chat_completions`.
- Configured context: `160000`.
- `HERMES_CUSTOM_127_0_0_1_8888_API_KEY` was confirmed PRESENT in `~/.hermes/.env`; its value is intentionally not recorded.
- Piper TTS configuration and voice path were present in the inspected config; no TTS test was performed in this checkpoint.

### systemd state — OBSERVED / INCOMPLETE
The latest user-provided `systemctl is-active` output showed:
- `hermes-gateway.service`: `inactive`.
- `llama-server.service`: `inactive`.

The old `llama-server.service` is the legacy Hermes model server and must remain stopped in the shared-one-model architecture. Do not start it: Unsloth owns the only model server in this design.

The existing Hermes Gateway is not currently verified as running. Its unit definition and journal have not yet been inspected in this checkpoint. Next action is read-only inspection of `systemctl status`, `systemctl cat` and `journalctl` for `hermes-gateway.service`; do not start or edit it before examining the evidence.

This checkpoint supersedes the earlier statement that the Gateway was active at the time of a previous test. Runtime state is time-dependent; preserve earlier successful tests as historical evidence, not as current status.


---

## Correction — Gateway unit lookup scope, 2026-10-31

The user ran `systemctl status/cat/journalctl` in the **system** scope (without `--user`). All three outputs showed that `hermes-gateway.service` is not installed/known in the system manager:
- `Unit hermes-gateway.service could not be found.`
- `No files found for hermes-gateway.service.`
- No journal entries for that system-scope unit.

This does **not** establish that Hermes Gateway is absent or stopped globally. The Linux Hermes documentation describes the default install as a per-user systemd service at `~/.config/systemd/user/hermes-gateway.service`; system scope is an explicit `--system` install. The default CLI command `hermes gateway status` inspects the selected installation's service. Therefore current Gateway installation/scope is **UNKNOWN**, and the previous unqualified `systemctl is-active` outputs must not be interpreted as a confirmed Gateway service state until the correct scope is checked.

Next: run the documented read-only `hermes gateway status`, then inspect `systemctl --user` status/unit/journal. Do not install, start, or edit anything until these checks identify the current service state and existing files.
Official docs: https://hermes-agent.nousresearch.com/docs/user-guide/messaging
