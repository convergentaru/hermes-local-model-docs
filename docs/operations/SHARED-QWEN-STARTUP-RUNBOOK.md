# Shared Qwen startup runbook — Unsloth + Hermes + Claude Code

Дата актуального checkpoint: 2026-10-31  
Статус документа: IN PROGRESS. Это поэтапная процедура; не считать её завершённым reboot/autostart runbook, пока не пройдены все acceptance checks.

## Целевая схема

- Один файл модели: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- Один inference server, жизненным циклом которого управляет Unsloth CLI.
- Unsloth client API: `http://127.0.0.1:8888/v1`.
- Hermes — отдельный клиент через Custom / OpenAI Chat Completions.
- Claude Code — отдельный клиент через поддерживаемый Unsloth Anthropic-compatible маршрут.
- Память, сессии, инструменты и роли двух агентов не объединяются.
- Текущая конфигурация сервера: context 160000, parallel 1.
- Запросы двух клиентов используют один слот и могут обслуживаться последовательно.

## Жёсткие правила

1. Не запускать модель напрямую командой `llama-server`; запускать через установленный `unsloth` CLI.
2. Не запускать legacy `llama-server.service` Hermes: это второй inference server.
3. Не использовать `unsloth start hermes` для восстановления существующего Hermes: требуется сохранить существующий Gateway/config/memory.
4. Не менять context 160K, parallel, GPU placement или модель без отдельного теста и решения.
5. Не считать процесс/порт доказательством готовности: нужен реальный запрос и ответ.
6. Не записывать API key и значения из `.env` в GitHub.

## Phase 0 — preflight (проверка перед запуском)

До запуска нового процесса проверить, не работает ли уже Unsloth/llama-server. Не запускать второй экземпляр, если существующий endpoint уже отвечает.

Проверить:
- состояние GPU/RAM;
- процессы Unsloth и llama-server;
- занятость порта 8888;
- состояние `hermes-gateway.service` и legacy `llama-server.service`.

**Acceptance:** установлено, что именно сейчас запущено, нет ли уже работающей модели, и какой процесс владеет endpoint. Не завершать процессы массовым `pkill`.

## Phase 1 — запуск модели через Unsloth (VERIFIED 2026-10-31)

Проверенная команда, выполненная пользователем:

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

Наблюдавшийся результат:
- Unsloth CLI 2026.10.11.
- Модель загружена; llama-server сообщил ready.
- Unsloth API доступен на `127.0.0.1:8888`.
- Внутренний порт llama-server в том запуске был `53815`; он динамический, не прописывать его в конфигурации клиентов.
- `GET /v1/models` вернул HTTP 200; Qwen3.5-9B-Q4_K_M загружена; configured context 160000; native/max context reported 262144.
- Реальный Chat Completions запрос вернул HTTP 200 и ожидаемый ответ.

**Acceptance:** модель загружена, `/v1/models` показывает её loaded, реальная генерация через `http://127.0.0.1:8888/v1` успешна.

**Примечание:** в этой команде передан `--disable-tools`. Возможность agent-side tools у Hermes и Claude Code должна проверяться отдельно; не делать вывод только по этому флагу.

## Phase 2 — восстановление существующего Hermes Gateway (PENDING)

Последнее наблюдение 2026-10-31:
- `hermes-gateway.service`: inactive.
- `llama-server.service`: inactive.
- Hermes config уже указывает Custom provider на `http://127.0.0.1:8888/v1`, модель `Qwen3.5-9B-Q4_K_M`, `chat_completions`, context 160000.
- Env variable `HERMES_CUSTOM_127_0_0_1_8888_API_KEY` присутствует в `~/.hermes/.env`; значение секрета не документируется.
- Piper TTS config присутствует; TTS не тестировался в этом checkpoint.

Сначала выполнить только read-only диагностику:

```bash
systemctl status hermes-gateway.service --no-pager -l
systemctl cat hermes-gateway.service
journalctl -u hermes-gateway.service -n 40 --no-pager
```

Не запускать Gateway вслепую и не редактировать unit до чтения его ExecStart, EnvironmentFile и журнала. После выяснения причины восстановить именно существующий Gateway, не создавая второй Hermes instance и не меняя память/TTS без необходимости.

**Acceptance:** существующий Gateway active; реальный Hermes запрос проходит через него и использует Unsloth endpoint; логи подтверждают отсутствие отдельного Hermes llama-server. Отдельно проверить, что Hermes toolset работает.

## Phase 3 — подключение Claude Code к уже запущенному Unsloth (PENDING)

Использовать только проверенную команду/режим установленной версии Unsloth CLI. Не запускать дополнительный сервер. В более раннем тесте использовался `unsloth start claude --no-serve`, но в текущем runtime это ещё не перепроверено.

**Acceptance:** Claude Code отвечает на тестовый prompt; его base URL указывает на текущий Unsloth endpoint; дополнительный llama-server/model process не появился; agent-side tools проходят отдельный smoke test.

## Phase 4 — общая проверка и последовательность после reboot (PENDING)

Проверить:
1. Ровно одна загруженная копия Qwen и один inference server.
2. Unsloth API отвечает и выполняет генерацию.
3. Hermes Gateway отвечает и Hermes CLI использует Custom provider Unsloth.
4. Claude Code отвечает через тот же backend.
5. Hermes memory/session и Piper TTS сохранены; TTS отдельно проверен.
6. При `--parallel 1` два агента не считаются одновременно генерирующими; зафиксировать фактическое поведение очереди.
7. Перезагрузка и повторный запуск проверены на реальной машине; только после этого документировать автозапуск/systemd или короткий recovery script.

**Acceptance:** все проверки пройдены после чистого reboot; команды, порядок, ожидаемые результаты, recovery и rollback записаны. До этого runbook остаётся IN PROGRESS.

## Текущий следующий шаг

Получить вывод Phase 2 (status, unit, journal) и на его основании определить безопасное восстановление существующего Hermes Gateway. См. также `NEXT_ACTION.md`, `CURRENT_STATE.md` и `EXPERIMENT_LOG.md`.


---

## Gateway scope correction — 2026-10-31

The initial system-scope lookup returned `Unit hermes-gateway.service could not be found`. That only means the system manager has no unit by this name. Hermes' current Linux documentation says the normal Gateway install is a user service, located under `~/.config/systemd/user`; a system unit is an explicit `hermes gateway install --system` choice.

Before attempting Phase 2 recovery, use these read-only checks:

```bash
hermes gateway status

echo "=== USER GATEWAY UNIT ==="
systemctl --user status hermes-gateway.service --no-pager -l

echo
echo "=== USER UNIT DEFINITION ==="
systemctl --user cat hermes-gateway.service

echo
echo "=== USER GATEWAY JOURNAL ==="
journalctl --user -u hermes-gateway.service -n 40 --no-pager
```

Do not install/start/restart the Gateway yet. First determine whether the user unit exists, whether a Gateway process is running outside systemd, or whether this Hermes install uses another service name/profile. Official source: https://hermes-agent.nousresearch.com/docs/user-guide/messaging


---

## Actual Gateway status — user service already running (2026-10-31)

The prior Phase 2 "Gateway recovery" diagnosis is superseded. User-provided output proves:
- `hermes gateway status` → User gateway service is running.
- The user unit `~/.config/systemd/user/hermes-gateway.service` is active and enabled.
- systemd linger enabled.
- Main PID 1822 during the check.

Therefore Phase 2 does not require reinstalling or starting the Gateway. The system-scope unit lookup was the wrong manager for this installation.

The remaining warning is at the messaging-platform layer: Gateway reports no messaging platforms enabled; WhatsApp is enabled but has no bot credential / is not paired. This does not stop the local Gateway daemon. Messaging setup is separate from the local Hermes CLI inference test.

### Next acceptance test: Hermes → existing Gateway → Unsloth

```bash
hermes chat --oneshot -q "Ответь строго одной строкой: HERMES_UNSLOTH_OK"
```

A model-generated `HERMES_UNSLOTH_OK` confirms the local Hermes CLI/Gateway request path against the configured Custom Unsloth endpoint. Capture errors exactly if the request fails. Do not restart the Gateway before this test.

Official Hermes docs: https://hermes-agent.nousresearch.com/docs/user-guide/messaging and https://hermes-agent.nousresearch.com/docs/reference/cli-commands


---

## Phase 2 result — existing Hermes and Unsloth inference route verified (2026-10-31)

The existing Gateway daemon is active/enabled as a user service. The Hermes CLI smoke test also succeeded: Hermes restored model `Qwen3.5-9B-Q4_K_M (custom:unsloth-qwen-160k)` and returned the exact expected response `HERMES_UNSLOTH_OK` to the test prompt.

Acceptance distinction:
- Hermes CLI → Custom provider → Unsloth: **VERIFIED**.
- Gateway daemon process: **VERIFIED RUNNING**.
- Gateway inbound messaging integrations: **NOT CONFIGURED / NOT TESTED** (startup says no messaging platforms enabled; WhatsApp is unpaired).
Do not mark messaging adapters as verified based on the CLI test.

The Gateway does not need to be restarted for the next step. Proceed to Claude Code against the already-running Unsloth endpoint.


---

## Phase 3 result — Claude Code acceptance passed (2026-10-31)

The user ran:
```bash
unsloth start claude --no-serve
```

Claude Code v2.1.286 displayed model `Qwen3.5-9B-Q4_K_M` and returned exact expected response `CLAUDE_UNSLOTH_OK` to the test prompt.

Combined with the previous Hermes CLI Custom-provider response `HERMES_UNSLOTH_OK`, both independent clients have now passed real generation smoke tests against the intended Qwen/Unsloth setup.

**Do not repeat** the Hermes or Claude smoke tests and do not restart the Gateway. Remaining immediate acceptance step: count exact `llama-server` processes once and inspect their command lines to verify the one-server invariant. Then update the final run order. A clean reboot test is still outstanding.


---

## Process-count audit — 2026-10-31: two llama-server processes found

The final process audit returned 2:
- PID 1823 — legacy Hermes server, port 18434, Hermes model presets and auto-load manager.
- PID 10358 — intended Unsloth Qwen server, internal port 53815, context 160000, parallel 1.

The architecture is **not yet one-server-clean** at the process level. The legacy process may be a model-management server without a loaded model; that remains unverified. Do not stop it on process count alone.

Next:
1. Map PID 1823 to its exact user unit with `systemctl --user status 1823`.
2. Inspect the identified unit and journal; do not assume it is `hermes-qwen35.service`.
3. Check the model list of server 18434 with a read-only authenticated request, keeping the API key out of terminal output and logs.
4. If the server is legacy/unused and has no active model/client dependency, plan a controlled stop of its exact owner unit, then verify the Gateway remains healthy and Hermes continues to use Unsloth.
5. Keep Unsloth PID 10358 alive throughout.

No process was stopped during the inventory. Do not mark one-server acceptance complete yet.


---

## Legacy Hermes router ownership identified — 2026-10-31

PID 1823 belongs to the user service `llama-server.service` at port 18434. It is a Hermes-bundled llama.cpp **router mode** process with `--models-max 1 --models-autoload` and a model preset file. Startup log says models are loaded on demand. Process RSS was only 11.4M (peak 242.3M), which suggests no model is currently loaded but does not prove it.

The separate `hermes-qwen35.service` is inactive/dead and disabled; it is not the PID 1823 owner.

Before retiring the router, check its authenticated `GET /models` state and inspect the unit. Stop it only after confirming there are no loaded models and no required dependency. Keep the Unsloth model/server running.


---

## Legacy router cleanup — model inventory confirmed empty (2026-10-31)

Both authenticated read-only endpoints on the old router `127.0.0.1:18434` returned all seven preset entries as `unloaded`. This proves the old router is not holding a second Qwen model. The remaining Unsloth process is the only server with the active Qwen model.

The old router is owned by user unit `llama-server.service`, enabled at `default.target`, with `Restart=on-failure`. Hermes Gateway is a separate active user service and has no declared dependency on this router. The actual Hermes CLI Custom → Unsloth test and Claude Code no-serve test both passed.

**Planned reversible cleanup (not yet executed):**
```bash
systemctl --user disable --now llama-server.service
```
This stops the idle router and removes its automatic startup link but preserves the unit file and presets. The command is reversible with `systemctl --user enable --now llama-server.service`. Do not delete model files or unit files.

Then verify Gateway active, old router inactive/disabled, Unsloth still responding, and exactly one llama-server process. Do not restart the Gateway or Unsloth.


---

## Legacy router deactivation — completed successfully (2026-10-31)

The user executed:
```bash
systemctl --user disable --now llama-server.service
```

Post-change verification from the user:
- `llama-server.service`: inactive.
- `llama-server.service`: disabled.
- `hermes-gateway.service`: active.
- `pgrep -xc llama-server`: 1.

Therefore the old empty Hermes router is no longer running or enabled, and the Unsloth-managed Qwen server is the only remaining llama-server process. Gateway stayed active. The legacy unit and model presets were not deleted.

### Final current-state acceptance
- Unsloth direct API before cleanup: VERIFIED.
- Hermes CLI Custom → Unsloth: VERIFIED.
- Claude Code → Unsloth with `--no-serve`: VERIFIED.
- Hermes Gateway user service: VERIFIED ACTIVE.
- One llama-server process after legacy cleanup: VERIFIED.
- Fresh Unsloth generation after cleanup: pending one API smoke test.
- Clean reboot test: pending; no Unsloth systemd autostart service has been configured.

Do not repeat previous client tests or Gateway diagnostics. Next, run one direct API response test after cleanup, then record the exact manual startup order and expected checks.


---

## Single-server invariant achieved — verified 2026-10-31

The user executed:
```bash
systemctl --user disable --now llama-server.service
```

Post-change results:
```text
Legacy server: inactive
Legacy unit: disabled
Hermes Gateway: active
llama-server process count: 1
```

The legacy router had all presets marked `unloaded` before being stopped. Its unit file, model presets and model files remain intact. This achieves the one-server process invariant without touching Unsloth or restarting the Gateway.

Next: make one direct Unsloth API generation request after cleanup. Then document the manual post-reboot startup sequence. Do not label auto-start complete until a real clean reboot is tested.


---

## API key scope note — 2026-10-31

Do not use the internal file `~/.unsloth/studio/auth/llama_api_key_*` as the credential for the public Unsloth wrapper endpoint on port 8888 unless explicitly verified. The user's request with that key received HTTP 401.

Unsloth's upstream CI helper obtains the public API key from the `unsloth run` startup banner (`API Key:`, commonly `sk-unsloth-...`) and uses it in the Bearer header for `/v1/models`:
https://github.com/unslothai/unsloth/blob/main/.github/scripts/serve-unsloth-run.sh

For the existing configuration, use `HERMES_CUSTOM_127_0_0_1_8888_API_KEY` from `~/.hermes/.env` for the public wrapper check. Keep the token out of logs and terminal output.


---

## Final post-cleanup functional acceptance — passed 2026-10-31

The user queried Unsloth wrapper `GET /v1/models` with the existing public wrapper credential from `~/.hermes/.env`. Output showed:
- `Qwen3.5-9B-Q4_K_M loaded`.
- all other returned presets unloaded.

A real `POST /v1/chat/completions` returned exact expected response:
`UNSLOTH_AFTER_ROUTER_STOP_OK`.

This is a post-cleanup test after the legacy Hermes router was stopped/disabled. Combined with:
- Hermes CLI → Unsloth: `HERMES_UNSLOTH_OK`.
- Claude Code v2.1.286 with `unsloth start claude --no-serve` → Unsloth: `CLAUDE_UNSLOTH_OK`.
- Hermes Gateway user service active.
- legacy router inactive/disabled.
- one llama-server process.

**Runtime recovery phase: VERIFIED COMPLETE.**

### Startup/reboot status
- Exact manual Unsloth launch command: verified in a running session.
- Hermes Gateway user-service autostart: enabled; linger enabled.
- Legacy router autostart: disabled.
- Claude Code attachment command: verified.
- Clean reboot and complete restart sequence: not yet performed.
- Unsloth systemd/boot autostart: not configured and not claimed.

Do not add an Unsloth systemd unit until its supported foreground/lifecycle management is researched and tested. Next work is to present/review the concise manual startup checklist; optionally validate it with a controlled reboot at the user's convenience.


---

## Manual startup checklist — current verified runtime sequence (2026-10-31)

**Purpose:** start the shared local model for Hermes and Claude Code after login/reboot without launching a second inference server. This sequence is based on commands that were executed successfully. A cold reboot has not yet been tested.

### 1. Confirm legacy router stays disabled

```bash
systemctl --user is-active llama-server.service || true
systemctl --user is-enabled llama-server.service || true
```

Expected: `inactive` and `disabled`. Do not enable this legacy port-18434 service.

### 2. Start the model through Unsloth CLI

Open a dedicated terminal and run:

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

Keep this terminal/process running while using the local agents. Do not start a standalone `llama-server` and do not close this terminal during the session.

Expected:
- Qwen3.5-9B-Q4_K_M is loaded.
- Unsloth wrapper listens at `127.0.0.1:8888`.
- Clients use `http://127.0.0.1:8888/v1`.
- Internal llama-server port is dynamically assigned; do not hardcode it.
- Context is 160000; parallel is 1.

### 3. Check the existing Hermes Gateway

The Gateway is already installed as a user service, enabled, and systemd linger is enabled. It normally starts with the user manager and survives logout. Check:

```bash
hermes gateway status
```

Expected: `User gateway service is running`. Do not reinstall or restart it as part of ordinary model startup. Current gateway message-platform adapters are not configured; that is separate from local inference.

### 4. Verify Hermes Custom provider (optional quick functional check)

Hermes Custom is configured for:
- base URL `http://127.0.0.1:8888/v1`;
- model `Qwen3.5-9B-Q4_K_M`;
- context 160000;
- API mode `chat_completions`.

Previously verified exact one-shot test:

```bash
hermes chat --oneshot -q "Ответь строго одной строкой: HERMES_UNSLOTH_OK"
```

Expected model response: `HERMES_UNSLOTH_OK`.

### 5. Launch Claude Code as a client of the existing server

```bash
unsloth start claude --no-serve
```

The `--no-serve` mode was verified with Claude Code 2.1.286. It must attach to the already-running Unsloth server, not launch another model server.

Previously verified prompt:
`Ответь строго одной строкой: CLAUDE_UNSLOTH_OK`.

### 6. Final process check

```bash
echo "=== LLAMA SERVER COUNT ==="
pgrep -xc llama-server || true
```

Expected: `1`. If the count is 0 or greater than 1, do not start/stop arbitrary processes; inspect the exact process command lines and unit ownership first.

### Known reboot/autostart limitations

- Hermes Gateway: user service enabled; linger enabled.
- Legacy Hermes router: user service disabled; do not re-enable.
- Unsloth model server: currently started manually with `unsloth run`; a dedicated systemd unit is not configured.
- Clean reboot acceptance: not yet performed.
- Therefore the current reliable procedure is **manual Unsloth startup**, followed by the two client connections. Do not claim that the model automatically starts at boot.
