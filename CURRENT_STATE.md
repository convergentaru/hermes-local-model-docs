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


---

## Correction from full user-scope Gateway output — 2026-10-31

The complete output of `hermes gateway status` and `systemctl --user` confirms that the existing Hermes Gateway is **ACTIVE and ENABLED** as a user service. Earlier conclusions based on system-scope `systemctl` were incorrect for this host and are superseded.

Observed:
- Unit: `/home/oleg/.config/systemd/user/hermes-gateway.service`.
- State: `active (running)`, `enabled`.
- Started: 2026-10-31 13:39:29 MSK.
- Main PID: 1822 (`hermes ... gateway run`).
- Child processes: MCP server PID 4378; Hermes MCP death supervisor PID 4379.
- systemd linger is enabled, so the user service survives logout.
- `hermes gateway status` explicitly reports: `User gateway service is running`.

Important application-level warnings from the same output:
- `No messaging platforms enabled.`
- WhatsApp is configured/enabled but no profile has a bot credential; it is not being served / not paired.
- No environment user allowlists are configured; gateway logs describe pairing/allowlist default policy.
These warnings do not mean the Gateway daemon is stopped. They mean it currently has no active messaging platform configured to receive bot messages.

Historical log evidence:
- At 13:35:54 the previous Gateway process made 3 failed custom-provider attempts to `http://127.0.0.1:8888/v1`, ending with `APIConnectionError`.
- It received SIGTERM at 13:38:58 and the current process started at 13:39:29.
- The current startup at 13:39:48 reports no enabled messaging platforms. It has not yet been proven with a fresh end-to-end model request after the successful Unsloth startup.

Unit inventory also showed:
- `hermes-gateway.service`: enabled.
- `hermes-qwen35.service`: disabled (do not start; inspect only if its role becomes relevant).
The system-scope query for `hermes-gateway.service` returned not found; that scope is irrelevant because the actual Gateway runs in the user manager.

Next test: a single Hermes CLI one-shot query through the existing Gateway to verify Gateway → Custom provider → Unsloth. No Gateway restart, install, or unit edit is required for this test.


---

## Hermes CLI → Unsloth functional smoke test — 2026-10-31

**Status: VERIFIED.**

The user resumed Hermes session `local-bd95986af8a0ecfcfc909532acc3d5ae08730dee0c92b157d4e21eba2c508371`. The restored model was shown as `Qwen3.5-9B-Q4_K_M (custom:unsloth-qwen-160k)`. Previous conversation displayed:
- User prompt: `Ответь строго одной строкой: HERMES_UNSLOTH_OK`
- Hermes response: `HERMES_UNSLOTH_OK`

This confirms that the Hermes CLI's custom provider route to the shared Unsloth/Qwen endpoint can generate a response. It does **not** test inbound messaging through Telegram/WhatsApp or other Gateway messaging adapters. The Gateway daemon remains independently confirmed active as a user service; its startup log reported no enabled messaging platforms and WhatsApp unpaired/unconfigured.

Architecture checkpoint:
- Unsloth Qwen direct API: VERIFIED.
- Hermes CLI Custom → Unsloth: VERIFIED.
- Hermes Gateway daemon: VERIFIED RUNNING (user systemd service).
- Gateway inbound messaging platform: NOT CONFIGURED / NOT TESTED.
- Claude Code → same Unsloth endpoint: pending fresh retest in this checkpoint.
- One inference server/model and process inventory should be confirmed once after Claude attachment.

The Hermes CLI output returned to the interactive prompt after showing the resumed one-shot session. Do not treat this as a Gateway failure; the model response itself succeeded.


---

## Claude Code → shared Unsloth functional smoke test — 2026-10-31

**Status: VERIFIED.**

The user launched Claude Code through the existing Unsloth-managed service using:
```bash
unsloth start claude --no-serve
```

Claude Code reported:
- Version: `2.1.286`.
- Model label: `Qwen3.5-9B-Q4_K_M`.
- Working directory: `/home/oleg`.
- User prompt: `Ответь строго одной строкой: CLAUDE_UNSLOTH_OK`.
- Exact model response: `CLAUDE_UNSLOTH_OK`.
- Completion: 14:36; ~21 seconds.

This is a successful functional smoke test through the Unsloth no-serve connection path. Together with the previously successful Hermes CLI Custom-provider test, both independent agent clients have now returned their exact expected strings using Qwen3.5-9B-Q4_K_M.

### Current acceptance matrix
- Unsloth model load and direct OpenAI-compatible API: VERIFIED.
- Hermes CLI Custom → Unsloth: VERIFIED.
- Existing Hermes Gateway user service: VERIFIED RUNNING.
- Claude Code 2.1.286 via `unsloth start claude --no-serve`: VERIFIED for text generation.
- Messaging platforms through Gateway: NOT CONFIGURED / NOT TESTED.
- One-and-only-one inference server at this exact moment: final process inventory pending.
- Clean reboot and full ordered startup: NOT YET TESTED.

Next: one read-only process inventory using exact process name `llama-server`; avoid broad pgrep patterns that match Hermes wrapper processes. Then complete the final startup runbook with a clear preflight and recovery order. No restart is required now.


---

## Final process inventory — two active llama-server processes observed 2026-10-31

The user ran `pgrep -x llama-server` and received count **2**. Exact executable-name process details:

1. **PID 1823**, PPID 1645, executable `/home/oleg/.hermes/tools/llamacpp-cuda-11370-linux-x64/llama-server`, listening argument `--port 18434`. Command includes `--models-max 1 --models-autoload`, metrics/slots, and Hermes preset file `/home/oleg/.hermes/runtimes/llamacpp/presets.ini`. The process command line contains an API key; the secret value is deliberately not recorded.
2. **PID 10358**, PPID 10257, executable `/home/oleg/.unsloth/llama.cpp/llama-server`, serving `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf` on internal port `53815`, with `--parallel 1` and `-c 160000`. This is the intended Unsloth-managed Qwen server.

**Interpretation:** two llama-server processes are definitely running, so the one-server invariant is not yet met. However, PID 1823 is a model-management server with `--models-autoload` and a presets file; the process listing alone does not establish whether it currently has a model loaded. Do not say there are two loaded copies of Qwen until the legacy server's model list/runtime is checked.

The legacy process is a child of the user systemd manager (PPID 1645). The user manager previously listed `hermes-qwen35.service` as disabled, but disabled means not enabled for automatic startup; it does not prove the unit is inactive. The exact owner unit for PID 1823 is still **UNKNOWN** and must be identified using `systemctl --user status 1823`, then inspect the corresponding unit and journal.

**Safety:** do not kill PID 1823 or stop any service until the unit owner and currently loaded models are confirmed. Keep Unsloth PID 10358/model running. Do not start any other inference server.

Updated target: identify PID 1823's unit, check whether port 18434 has any model loaded, and only then decide whether the legacy service can be safely stopped to achieve one inference server.
