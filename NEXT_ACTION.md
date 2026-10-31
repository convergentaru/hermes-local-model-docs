# NEXT_ACTION — один следующий шаг

Дата: 2026-10-31

## Приоритет: сначала проверить slots, не начинать общий тюнинг вслепую

Рабочая гипотеза пользователя: возможно, для двух агентов достаточно одного llama-server с одной загруженной Qwen3.5-9B и двумя параллельными slots. Проверить это по фактической конфигурации и тестом. Не менять конфигурацию до baseline.

## Два независимых задания, которые нельзя смешивать

### Hermes — перевод

- Hermes занимался отдельной задачей перевода.
- Последнее сообщение Hermes: `Gateway disconnected; turn outcome is unknown`.
- WebSocket оборвался с `ConnectionClosedError: keepalive ping timeout`.
- Hermes сообщил, что нужно возобновить напечатанную session ID, чтобы проверить, завершилось ли задание или было прервано.
- **Не отправлять перевод повторно**, пока не проверен исходный session ID и состояние результата.
- Эта ошибка сама по себе не доказывает неисправность llama-server.

### Claude Code — аудит контекста

- Claude Code отдельно выполнял аудит контекстного окна и Auto-Compact.
- Он сообщил: `Autocompact is thrashing: the context refilled to the limit within 3 turns of the previous compact, 3 times in a row.`
- Были прочитаны `.claude.json`, Hermes runtime `server.json`, `presets.ini` и `QWEN_AUDIT_REPORT.md` (385 строк); также был открыт файл credential с API-ключом — секреты не копировать в отчёты.
- Не запускать новый параллельный аудит в том же сеансе, пока Claude Code не вернётся к приглашению ввода и не будет сохранён промежуточный результат.
- Следующий шаг для Claude Code: сохранить краткий `CONTEXT_AUDIT_PROGRESS.md`, затем продолжить проверку малыми порциями.

## Очерёдность следующей рабочей сессии

1. Проверить исход Hermes translation session по напечатанному session ID; не дублировать работу.
2. Получить и сохранить итог/промежуточный отчёт Claude Code по текущему аудиту контекста.
3. T-005 — read-only исследование и проверка одного llama-server с двумя slots для двух независимых агентов. Сначала зафиксировать текущую конфигурацию; не запускать вторую копию Qwen.
4. Если slots-схема подтверждена и эксперимент проходит, спланировать безопасное объединение маршрутизации двух клиентов к одному endpoint. Только после согласования менять конфигурацию.
5. T-004 — разобраться с Auto-Compact thrashing и размером контекста уже в целевой архитектуре.
6. T-001/T-002 — оставшуюся диагностику и настройку выполнять по необходимости, не дублируя проверки, уже покрытые T-005.
7. После каждого этапа сохранять подтверждённые факты в журнале.

Полный список: [TASKS.md](TASKS.md).

## Техническое уточнение по slots

- `--parallel N` / `n_parallel` задаёт число параллельных серверных slots, а не число загруженных моделей.
- Slots позволяют одному экземпляру сервера обслуживать несколько запросов; они не означают бесплатную память: активные последовательности используют KV cache и вычислительные ресурсы.
- Не считать, что каждый slot автоматически получает полный `--ctx-size`. Семантика общего контекста и per-slot context зависит от параметров и версии сборки; проверить `--kv-unified-per-slot` и фактический `/slots`.
- Unsloth Studio управляет числом slots через `n_parallel`; его VRAM fitter может запустить меньше slots, чем запросил пользователь. Проверять фактическое значение после загрузки.
- Slots обычно назначаются сервером свободным запросам динамически; отдельное постоянное закрепление агента за номером slot не предполагать без подтверждения API.

## Последнее известное состояние (не считать актуальным без проверки)

- Hermes llama-server ожидался на `:18434`; в предыдущем рабочем состоянии пользователь останавливал `llama-server.service`.
- Unsloth worker ранее слушал `:52681`, но этот порт динамический и мог измениться.
- В прежней конфигурации Unsloth были `--parallel 4`, `-c 65536`, `--kv-unified`, `--slot-save-path`, `--ctx-checkpoints 5`.
- Не запускать вторую копию Qwen, не удалять модели/профили/credentials, не менять context/offload/slots без проверки реального профиля и памяти.

## Правила

- Hermes перевод и Claude Code аудит — независимые задания.
- Не смешивать их session ID, логи, результаты и команды.
- Не повторять неизвестно завершившуюся работу до проверки состояния.
- Никаких изменений конфигурации без согласования.
- Не публиковать API-ключи, токены и credential-файлы.

## Уточнение: одна модель, несколько slots и загрузка нескольких моделей — разные механизмы

По итогам обсуждения 2026-10-31 зафиксировать отдельно:

- **Одна загруженная модель + несколько slots:** один процесс llama-server держит одну копию весов Qwen3.5-9B и может обслуживать несколько независимых запросов через slots. Количество slots задаётся параметрами вроде `--parallel N` / `n_parallel`. Slot — это рабочий контекст/канал обработки запроса, а не ещё одна загруженная модель.
- **Несколько загруженных моделей:** это отдельная функция управления памятью Unsloth Studio. Переключатель **Keep multiple models loaded** разрешает держать в памяти несколько разных моделей. Он не создаёт slots и не нужен для схемы «одна модель — два агента».
- Следовательно, если цель — Hermes и Claude Code на одной Qwen, надо проверять число реально работающих llama-server процессов, загруженные ими model path и фактическое число slots. Наличие пункта интерфейса «загрузить две модели» само по себе не означает, что для двух агентов нужны две модели.
- Пока не установлено, какой именно компонент/процесс загружает вторую модель и какую именно. Это остаётся вопросом для read-only аудита; не делать вывод по одному экрану Unsloth и не останавливать процессы наугад.

### Зафиксированные предпочтения конфигурации Unsloth (не менять без отдельного решения)

- Custom llama.cpp folder: `/home/oleg/llama.cpp/build-cublas/bin`.
- Модель: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- **Keep model in GPU memory: ON**.
- **Keep multiple models loaded: OFF** — не держать несколько разных моделей одновременно.
- **Idle auto-unload: 0**.
- **Switch model by request: OFF**.
- Не запускать дополнительные экземпляры llama-server и не проводить переустановки/тесты без отдельного согласования.

### Вывод для следующего этапа

Проверять архитектуру «одна копия Qwen + два slots + два клиента», а не включать загрузку нескольких моделей. Сначала только зафиксировать фактические процессы, model path, endpoints, `n_parallel` и ответ `/slots`; затем отдельно согласовать короткий тест двух независимых запросов. Историю и tool state Hermes и Claude Code держать раздельно.


---

## Latest superseding note — 2026-10-31

Older items proposing a new two-server/two-agent slots investigation are historical and have been superseded by the successful shared-server setup recorded in `SESSION_BOOTSTRAP.md`. Do not reopen that work unless a new failure or requirement appears.

### Current next action
1. Recover the prior Hermes SystemRescue translation session using `session_search` for `SystemRescue`, `systemrescue-help-original`, translation and Russian help ISO.
2. Check actual `/usage` and compression telemetry; do not repeat the unsupported claim of a hard 70K context cap.
3. Do not rerun translation until the previous session/result has been checked.

### Hermes ↔ Claude Code
Research is recorded in `docs/integrations/hermes-claude-code.md`. No additional integration is planned now. Keep the two clients independent for Screenlife comparisons; revisit one-way MCP Serve only for a concrete use case.


---

## Latest next action — SystemRescue translation output verification (2026-10-31)

The Hermes session-recovery report has arrived. Do not ask the user to repeat task context and do not rerun translation.

First inspect subagent session `20261028_133323_20e490` and parent `20261028_132200_f170ad` for the eight source/output filenames, exact absolute output directory, file sizes, hashes and success/failure details. Confirm that every output file exists and is non-empty. Then compare the local artifacts and decide what reviewed text files should be committed to `convergentaru/pc-rescue-platform`.

Do not overwrite or regenerate translations. Do not build an ISO until output files have been recovered, reviewed and archived.

Detailed audit: https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md


---

## Future model evaluation (not installed or scheduled)

Research note: `docs/model-selection/2026-10-31-upgrade-candidates.md`.

Before downloading a larger model, perform a read-only inventory of the user's existing Unsloth model collection, especially the previously used `Qwen3.6-35B-A3B-UD-IQ2_XXS.gguf`. If the file exists, validate it and consider a one-model-at-a-time trial. Otherwise consider Qwen3.8-27B `UD-Q3_K_XL` as the new primary candidate.

No configuration change is authorized by this research. Keep the working Qwen3.5-9B baseline intact, one server only, and preserve the 160K target context. Acceptance must include real memory placement, 160K functional stability, tool calling and identical Hermes/Claude Code tests. Do not assume larger parameter count automatically means better speed or quality.


---

## New user priority — audio first, model upgrade later (2026-10-31)

The user explicitly set this order:
1. **Audio/voice work first.** Continue with the audio task as the next active priority, using the existing voice documentation and the user's next concrete direction. Do not assume which exact voice subtask they mean without seeing the work context.
2. **Larger model only afterwards.** The Qwen3.8-27B / Qwen3.6-35B-A3B investigation is postponed until audio work is addressed. No download, no model swap and no server changes now.

Why defer the 27B model:
- RTX 3060 has 12 GB VRAM; system RAM is around 12 GB with 4 GB swap.
- A 13.1 GB Qwen3.8-27B GGUF file is only the weights, not total runtime memory. KV cache for 160K context and server/desktop overhead also need memory.
- The user explicitly does not want another oversized model attempt that fails to load.
- Preserve Qwen3.5-9B known-good setup and the 160K target context.

After audio: inspect actual free RAM/VRAM, inventory the existing collection for `Qwen3.6-35B-A3B-UD-IQ2_XXS.gguf`, then decide whether to test that existing file or download a separate Qwen3.8-27B quant. Never overwrite the 9B baseline or run two large servers simultaneously.

Separate pending work remains: verify the eight SystemRescue translations reported by Hermes. Do not treat that task as completed until the actual files are located and reviewed.


---

## Latest SystemRescue translation status — second Hermes report (2026-10-31)

Hermes now reports only two existing translated Markdown files in `/home/oleg/fcm-opencode-test`:
- `Configuring_SystemRescue_sysconfig.md` — 15,020 bytes; SHA-256 `c9e4d2e1351dc182b0032fa97eb3e91a6bb6fe3c9da436f199addaabc232c066`.
- `Downloading_and_burning.md` — 3,008 bytes; SHA-256 `99198e2a28c27f805bfa0bcd8b19e4a30b418d1feee405ec659c90939fac8699`.

Both are reported to have the same original and translated paths, so they may have replaced originals in place. Do not edit, overwrite, move or retranslate them until byte-for-byte preservation is planned. The other six files were not found in that directory; their exact names have not yet been extracted from the subagent transcript.

Next SystemRescue actions:
1. Obtain exact original eight filenames from subagent `20261028_133323_20e490` prompt/transcript.
2. Read-only locate the six other outputs by exact filename; do not search the whole disk indiscriminately.
3. Check `git status` and remote in `/home/oleg/fcm-opencode-test`; preserve all uncommitted data.
4. Recalculate hashes/sizes directly on the machine and compare the two outputs with exact upstream originals after preserving them.
5. Update the canonical audit before any translation rerun or ISO build.

Context report: Hermes gives Config `context_length=131072`, `auto_compress_threshold=100000`, historical server `-c 160000`, and subagent `last_prompt_tokens=32964`. Do not infer compression count from cache-write tokens. The SSH/QEMU session timestamp still reports 2024 despite its 20261024 ID; raw metadata needs resolution.

Detailed audit: https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md

The separate user priority remains unchanged: audio work first; larger-model download later.


## Benchmark protocol for any future model switch

Follow `docs/model-selection/BENCHMARK-PROTOCOL.md`: compare identical tasks, measure TTFT, prefill/generation tok/s, peak VRAM/RAM, context stability, tool-call success and output correctness. Preserve raw traces and failed runs. Do this only after the user's current audio priority is addressed.


---

## User-requested comparison — HOME directory audit (2026-10-31)

Run the protocol in `docs/operations/HOME-DIRECTORY-AUDIT.md`:
1. Start with a tiny simultaneous no-tools probe in Hermes and Claude Code to observe contention for the one current Unsloth slot.
2. Run identical bounded read-only HOME metadata audits sequentially in the two agents.
3. Cross-review each report in the other agent.
4. Bring the reports back for comparison and sanitized GitHub publication.

Do not inspect sensitive contents or make changes. Do not run both full audits concurrently while `--parallel 1` is configured. This task does not authorize changing model context, slots or server configuration.


---

## User-requested long-running agent pilot — HOME inventory (2026-10-31)

Use `docs/operations/LONG-RUNNING-AGENT-WORK-PAPERCLIP.md`:
1. Hermes performs a measured, read-only storage/filesystem inventory with progress checkpoints.
2. Claude Code performs a complementary read-only development-project/Git workspace inventory.
3. Run agents sequentially while Unsloth remains `--parallel 1`.
4. Exchange the two reports and have each agent cross-review the other.
5. Produce a sanitized joint report and a human-reviewed action backlog; do not perform cleanup.

Paperclip research confirms built-in Hermes and Claude adapters with heartbeats and session persistence, but Paperclip is not verified installed/configured on this host. Before overnight use, verify local installation/version, test both adapters against the existing custom Unsloth/Qwen endpoint, and verify Stop/resume. Do not switch providers or start extra model servers.

The separate audio-first priority still applies before any larger-model download. No model upgrade is part of this audit.


---

## Copy/paste prompts ready — long-running HOME audit

Detailed role split, multi-phase work and safety gates:
- `docs/operations/HOME-AUDIT-LONG-TASK-PROMPTS.md` — Task 1 Hermes storage/filesystem audit; Task 2 Claude Code project/Git workspace audit; Task 3 cross-review.
- `docs/operations/LONG-RUNNING-AGENT-WORK-PAPERCLIP.md` — Paperclip heartbeat design, adapter integration questions, sequential scheduling under `--parallel 1`, overnight acceptance gate.

No local scan has been run and no agent has been launched by ChatGPT. The user needs to paste Task 1 into a fresh Hermes session, then Task 2 into a fresh Claude Code session. Do not run both full tasks simultaneously: one Qwen server slot serializes them. After reports arrive, perform reciprocal review.

Paperclip unattended/overnight configuration remains **NOT ENABLED** until adapter smoke tests confirm that both agents stay on the existing custom Unsloth/Qwen endpoint, sessions resume across heartbeats, and Stop controls work.


---

## Latest active task — recover existing Hermes Gateway without starting a second model server (2026-10-31)

### Verified baseline
- Unsloth CLI `unsloth run` loaded `Qwen3.5-9B-Q4_K_M.gguf` with context 160000 and `--parallel 1`.
- Client endpoint `http://127.0.0.1:8888/v1` returned HTTP 200 for both model listing and a real Chat Completions generation request.
- Internal llama-server port `53815` is dynamic; do not use it as the client endpoint.
- Hermes config already points to this endpoint using Custom / Chat Completions, model ID `Qwen3.5-9B-Q4_K_M`, context 160000.
- Hermes API-key environment variable is present in `~/.hermes/.env`; do not publish its value.
- Latest service status: `hermes-gateway.service = inactive`; `llama-server.service = inactive`.

### Immediate next step — read-only Gateway diagnosis
The user has been asked to run:

```bash
echo "=== GATEWAY UNIT ==="
systemctl status hermes-gateway.service --no-pager -l

echo
echo "=== GATEWAY UNIT CONFIG ==="
systemctl cat hermes-gateway.service

echo
echo "=== RECENT GATEWAY LOG ==="
journalctl -u hermes-gateway.service -n 40 --no-pager
```

Wait for this output before taking action. Determine whether the Gateway exited, failed, was stopped intentionally, or lacks required environment/config. Do not infer the cause.

### Hard constraints
1. Keep the currently running Unsloth session open; do not close its terminal.
2. Do not start `llama-server.service`: it is the legacy Hermes model server and would violate the one-model/one-server design.
3. Do not start a second `llama-server` manually.
4. Do not run `unsloth start hermes`; that creates a managed Hermes instance and risks bypassing the existing Gateway/config/memory.
5. Preserve Hermes Gateway, memory, sessions, Piper TTS and existing configuration. No edits until the unit/journal have been inspected.
6. Once the Gateway is diagnosed and restored, verify a real Hermes request through the existing Gateway and confirm it reaches the Unsloth endpoint.
7. Then verify Claude Code attaches to the same running Unsloth service without starting another model server. Use the installed CLI's actual help/known-good workflow; do not guess flags.
8. After every successful or failed step, append evidence to `EXPERIMENT_LOG.md` and update `CURRENT_STATE.md` / `NEXT_ACTION.md` as appropriate.

### Current status
- Unsloth model load and direct API: VERIFIED.
- Hermes provider configuration and env variable presence: OBSERVED.
- Existing Hermes Gateway: INACTIVE; cause UNKNOWN; diagnosis pending.
- Legacy Hermes llama-server service: INACTIVE; intentionally keep it that way.
- Claude Code connection in this latest runtime: NOT YET RETESTED.


---

## Correction to Hermes Gateway diagnosis — 2026-10-31

The last user check queried the system manager only and returned `Unit hermes-gateway.service could not be found`. Do **not** infer that the Gateway is missing or stopped: the normal Hermes Linux service is user-scoped unless explicitly installed with `--system`.

Next step is read-only:
1. `hermes gateway status` — official Hermes command to inspect the selected installation's default service.
2. `systemctl --user status hermes-gateway.service --no-pager -l`.
3. `systemctl --user cat hermes-gateway.service`.
4. `journalctl --user -u hermes-gateway.service -n 40 --no-pager`.

If the user manager reports the unit missing too, inspect the Hermes CLI status output and existing user unit files before considering any install. Do not run `hermes gateway install`, `start`, or `run` yet. Do not start the legacy `llama-server.service`.


---

## Latest active step — end-to-end Hermes → Gateway → Unsloth smoke test (2026-10-31)

The existing Hermes Gateway is already running and enabled as a **user service**. This is verified by the user's full output:
- `hermes gateway status`: User gateway service is running.
- `systemctl --user`: active (running), enabled.
- Unit path: `~/.config/systemd/user/hermes-gateway.service`.
- PID 1822; systemd linger enabled.

Do NOT repeat system-scope checks; they queried the wrong manager. Do NOT restart/install/reconfigure the Gateway.

The Gateway reports `No messaging platforms enabled`; WhatsApp is enabled but has no profile bot credential and is not paired. This is a messaging integration warning, not a stopped service.

The old 13:35:54 Gateway custom-provider attempt failed with `APIConnectionError` before the most recent confirmed Unsloth API success. A fresh end-to-end request is now required.

### One next action
Run exactly one documented Hermes one-shot chat through the running Gateway:

```bash
hermes chat --oneshot -q "Ответь строго одной строкой: HERMES_UNSLOTH_OK"
```

Expected: model-generated response `HERMES_UNSLOTH_OK`. Capture the complete output, including any error. This tests the existing Hermes CLI/Gateway session path and its configured Custom provider against Unsloth.

Do not run a second test, alter the provider, start a service, or touch `hermes-qwen35.service` until the first result is reviewed.

After success: test Claude Code on the already-running Unsloth server, then check the process list once to ensure one inference server. Gateway messaging platform setup (e.g. WhatsApp/Telegram) is a separate optional task and must not be mixed into this local CLI inference test.
