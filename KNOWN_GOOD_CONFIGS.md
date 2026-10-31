# KNOWN_GOOD_CONFIGS — проверенные конфигурации

Последнее обновление: 2026-10-31

В этом файле намеренно разделены подтверждённые конфигурации и исторические параметры. Наличие записи не означает, что компонент работает в текущем сеансе.

## 1. Unsloth Desktop — исторически проверенная база

Источник: [документация от 2026-10-10](docs/unsloth/studio-model-library-and-custom-llama-cpp.md).

- Model library: `/home/oleg/models`.
- GPU backend: CUDA.
- Custom Llama CPP Folder: `/home/oleg/llama.cpp/build-cublas/bin`.
- Проверялось наличие исполняемого `llama-server` и CUDA-библиотек.
- В тесте Qwen3.5-4B был получен ответ `UNSLOTH_CUDA_TEST_OK`; UI показывал 68.4 tok/s.

Статус: VERIFIED для того исторического теста Qwen3.5-4B. Не является доказательством работы Qwen3.5-9B сегодня.

## 2. Unsloth → Hermes Desktop — исторически проверенный маршрут

Команда из прежней документации:

```bash
unsloth start hermes --app
```

После загрузки модели команда добавляла провайдера Unsloth в конфигурацию Hermes Desktop. Визуальный Hermes затем вернул контрольную строку.

Статус: VERIFIED для исторического текстового теста. Не запускать Hermes параллельно с отдельной копией той же GGUF-модели.

## 3. Qwen3.5-9B — исторический профиль Unsloth

Модель:
`/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`

Параметры, наблюдавшиеся в прежнем профиле:
- Context / max sequence length: 65 536;
- Parallel: 4;
- Flash Attention: On;
- Context Shift: Off;
- KV Unified: On;
- Fit: On;
- Context Checkpoints: 5;
- Reasoning: Off;
- Load Mode: mmap+mlock.

Статус: OBSERVED. Перед использованием восстановить фактический профиль через GUI; не полагаться только на этот список.

## 4. Claude Code — исторический профиль подключения

- Base URL: `http://127.0.0.1:8888`.
- Model alias: `Qwen3.5-9B-Q4_K_M`.
- Context setting: 65 536.
- Auto-compact override: 90%.
- Max output tokens: 16 384.

Статус: OBSERVED. Подключение ранее работало, но конкретная команда запуска должна быть восстановлена из настроек/документации установленной версии.

## 5. Не использовать как проверенный запуск

Следующая команда завершилась ошибкой CLI о необходимости prompt/stdin при использовании `--print`:

```bash
unsloth start claude --model /home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf --max-seq-length 65536
```

Статус: FAILED на 2026-10-31. Не повторять без выяснения правильного интерфейса CLI.

## 6. Обязательные ограничения

- Не запускать одну и ту же Qwen GGUF одновременно через Hermes llama-server и Unsloth worker.
- Не предполагать, что порт worker постоянный.
- Не печатать API keys, токены и секретные конфиги.
- Не менять параметры контекста, parallel или offload без оценки RAM/VRAM.
- Перед правкой профиля сохранить резервную копию или зафиксировать исходные значения.


## 7. Unsloth CLI — current 2026-10-31 runtime checkpoint

**Status:** VERIFIED for model load and direct OpenAI-compatible API generation.

Exact user-executed command:

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
- Unsloth CLI `2026.10.11`.
- Client API: `http://127.0.0.1:8888/v1`.
- Internal llama-server port: `53815` in this run only; dynamic.
- Model loaded and server ready.
- `/v1/models` returned HTTP 200 and reported Qwen3.5-9B-Q4_K_M loaded, context 160000, native/max context 262144.
- A real Chat Completions request returned HTTP 200 and the expected response.

Do not substitute the internal port for the Unsloth API endpoint. Do not replace this launch with a direct `llama-server` command; Unsloth CLI is the required lifecycle manager for this setup.

Note: `--disable-tools` was present. Verify agent-side tool execution separately before claiming full agent functionality.

## 8. Hermes Custom provider — current configuration observed 2026-10-31

**Status:** OBSERVED; Gateway runtime test pending.

- Provider: `custom`.
- Base URL: `http://127.0.0.1:8888/v1`.
- Model: `Qwen3.5-9B-Q4_K_M`.
- API mode: `chat_completions`.
- Configured context: `160000`.
- Environment variable name: `HERMES_CUSTOM_127_0_0_1_8888_API_KEY`; confirmed present in `~/.hermes/.env`. Secret value is not documented.
- Fallback model configured: `Ministral-3-3B-Instruct-2512-Q4_K_M`; fallback behaviour has not been tested in this checkpoint.

The config is pointed at the correct Unsloth API. This alone does not prove the systemd Gateway has loaded the environment or can complete a request.

## 9. Legacy Hermes model service

Latest observed status: `llama-server.service = inactive`. Keep it inactive while Unsloth owns the single Qwen inference server. Do not start it as part of Hermes Gateway recovery.


## 10. Existing Hermes Gateway — user service confirmed 2026-10-31

**Status:** VERIFIED RUNNING as a user-scope service.

- CLI: `hermes gateway status` reported `User gateway service is running`.
- Unit: `/home/oleg/.config/systemd/user/hermes-gateway.service`.
- `systemctl --user`: active (running), enabled.
- Main PID: 1822 in the observed run.
- systemd linger: enabled.
- MCP child processes were present.

**Important:** `systemctl status hermes-gateway.service` without `--user` checks the system manager and returned unit-not-found. It must not be used to infer the status of this user-installed Gateway.

Gateway process health and messaging-platform readiness are separate:
- The daemon is running.
- Startup log says no messaging platforms are enabled.
- WhatsApp lacks a bot credential and is not paired.
- No env allowlists are configured; the documented pairing policy remains in effect.

Do not reinstall or restart this working service as part of the shared-model recovery. The next test is a fresh Hermes one-shot request through the existing Gateway.


## 11. Hermes CLI → Unsloth Custom provider smoke test — 2026-10-31

**Status: VERIFIED.**

User resumed session `local-bd95986af8a0ecfcfc909532acc3d5ae08730dee0c92b157d4e21eba2c508371`.
Restored model: `Qwen3.5-9B-Q4_K_M (custom:unsloth-qwen-160k)`.

The exact prompt and answer in the prior conversation were:
- Prompt: `Ответь строго одной строкой: HERMES_UNSLOTH_OK`
- Answer: `HERMES_UNSLOTH_OK`

This verifies Hermes CLI text generation through the configured Custom provider. It is not a test of Telegram/WhatsApp or other Gateway inbound messaging channels. Gateway daemon process health is separately verified; current Gateway startup said no messaging platforms are enabled.


## 12. Claude Code → shared Unsloth smoke test — 2026-10-31

**Status: VERIFIED.**

User launched:
`unsloth start claude --no-serve`.

Claude Code reported:
- Version `2.1.286`.
- Model `Qwen3.5-9B-Q4_K_M`.
- Exact response to prompt `Ответь строго одной строкой: CLAUDE_UNSLOTH_OK`:
  `CLAUDE_UNSLOTH_OK`.

This verifies a real generation through the Unsloth no-serve client path. Combined with the successful Hermes Custom-provider smoke test, both clients have generated through the intended shared Unsloth model. Exact process-count verification is a separate final read-only check.


## 13. Process inventory correction — two llama-server processes observed 2026-10-31

The intended one-server architecture has not yet been achieved at process level.

Observed processes:
- PID 1823: Hermes-bundled llama.cpp at `127.0.0.1:18434`, using Hermes model presets and `--models-autoload`.
- PID 10358: Unsloth-bundled llama.cpp at dynamic internal port `53815`, serving the Qwen3.5-9B GGUF with context 160000 and parallel 1.

The first process is a model-management server; whether it has a model loaded is not yet confirmed. Do not classify it as a second loaded Qwen instance without checking `/v1/models` on port 18434. Its owner unit must be identified using `systemctl --user status 1823`.

No process was stopped in this inventory step.


## 14. Legacy Hermes router — all presets unloaded (2026-10-31)

Authenticated read-only GET requests to `http://127.0.0.1:18434/models` and `/v1/models` returned seven preset models, all with status `unloaded`, including the Qwen3.5-9B preset.

The router process itself was active, but no model instance was loaded there. The active model is served by Unsloth. The idle router's user unit `llama-server.service` is enabled for default.target and can be stopped/disabled without deleting its unit, model presets, or model files. Deactivation is pending user execution and post-change verification.


## 15. Idle router cleanup — verified 2026-10-31

The user executed `systemctl --user disable --now llama-server.service`.

Post-check verified:
- Legacy Hermes router is `inactive`.
- Legacy Hermes router is `disabled`.
- Hermes Gateway user service is `active`.
- Exact process count `pgrep -xc llama-server` is `1`.

This leaves the Unsloth Qwen inference process as the only llama-server process. The old unit and presets remain on disk and can be re-enabled; they were not deleted. A fresh Unsloth API response after the cleanup is the next check.


## 16. Single-server cleanup — post-change verification passed 2026-10-31

After the user executed `systemctl --user disable --now llama-server.service`, output confirmed:
- legacy Hermes router inactive;
- legacy Hermes unit disabled;
- Hermes Gateway active;
- exact `llama-server` process count = 1.

This is the verified state for the one-model/one-server architecture. Legacy service files and presets are preserved. Post-cleanup API smoke test is still pending.


## 17. Unsloth health after legacy router shutdown — VERIFIED 2026-10-31

After disabling the old Hermes router, the public Unsloth wrapper returned the model inventory with `Qwen3.5-9B-Q4_K_M` marked `loaded`. A real Chat Completions request returned `UNSLOTH_AFTER_ROUTER_STOP_OK`.

This confirms the legacy router shutdown did not break the Unsloth service. The correct wrapper credential came from the existing Hermes environment variable; the internal llama-server key file had returned 401 and must not be used for this public wrapper check.

Combined with successful Hermes and Claude Code smoke tests, the runtime shared-model architecture is verified. Clean reboot/autostart remains unverified.
