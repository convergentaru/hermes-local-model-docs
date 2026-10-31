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
