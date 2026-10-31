# EXPERIMENT_LOG — журнал экспериментов

Все записи хронологические. Старые результаты не переписывать; новые результаты добавлять отдельной записью.

## 2026-10-31 — остановка параллельных AI-процессов

**Цель:** освободить GPU перед чистым запуском Unsloth и одной модели.

**Действие:** пользователь выполнил остановку процессов с шаблонами `llama-server|unsloth|hermes|claude|gbrain|openclaw` через `pkill -9 -f`.

**Результат:** пользователь сообщил, что видеопамять занята примерно на 0,5%.

**Статус:** OBSERVED. Числовой вывод `nvidia-smi` в журнал не приложен. Остановка относится к AI-процессам; системные процессы и рабочий стол не являются целью.

## 2026-10-31 — неудачная попытка запуска Claude через CLI

**Команда:**

```bash
unsloth start claude --model /home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf --max-seq-length 65536
```

**Результат:**

```text
Error: Input must be provided either through stdin or as a prompt argument when using --print
```

**Статус:** FAILED.

**Вывод:** эту команду нельзя предлагать как рабочую команду запуска. Пользователь помнит, что раньше модель выбиралась и настраивалась через графическое приложение Unsloth Desktop/Studio, с дополнительными параметрами. Нужно восстановить прежнюю последовательность по GUI и локальным настройкам.

## 2026-10-30 — исторический снимок двух Qwen процессов

В прежней диагностике одновременно наблюдались:
- Hermes llama-server, порт 46223, около 7590 MiB VRAM;
- Unsloth worker, порт 33085, около 3726 MiB VRAM;
- суммарно около 11842 MiB из 12288 MiB VRAM.

**Статус:** OBSERVED. Это объясняет перегрузку VRAM в том конкретном снимке.

## 2026-10-10 — Unsloth Desktop + Qwen3.5-4B

Источник: [документ настройки Unsloth Desktop](docs/unsloth/studio-model-library-and-custom-llama-cpp.md).

- Выбрана CUDA.
- Подключена собственная сборка llama.cpp: `/home/oleg/llama.cpp/build-cublas/bin`.
- Qwen3.5-4B Q4_K_M ответила `UNSLOTH_CUDA_TEST_OK`.
- UI показал 68.4 tok/s.
- Проверен текстовый маршрут Unsloth → Hermes Desktop через `unsloth start hermes --app`.

**Статус:** VERIFIED для тогдашней конфигурации и теста.

## 2026-10-10 — контекст Qwen3.5-4B

В работающем процессе наблюдались `-c 238592`, `--parallel 4`, `--fit off`. API сообщал `n_ctx=238592` и `n_ctx_train=262144`. VRAM в том снимке была занята на 11,425 MiB из 12,288 MiB.

**Статус:** OBSERVED. Не переносить эти параметры автоматически на Qwen3.5-9B.


---

## 2026-10-31 — аудит systemd Hermes и первая попытка jcode → Unsloth

**Сервисная схема по read-only аудиту пользователя:**
- `llama-server.service`: Hermes llama-server, `127.0.0.1:18434`, preset `/home/oleg/.hermes/runtimes/llamacpp/presets.ini`.
- `hermes-gateway.service`: отдельный unit; `After/Wants=network-online.target`; нет `Requires`, `BindsTo` или `PartOf` к llama-server.
- Hermes config: Qwen3.5-9B-Q4_K_M, provider llamacpp, `http://127.0.0.1:18434/v1`, chat_completions, fallback Ministral.
- Пользователь подтвердил LISTEN Unsloth llama-server на `:52681`, PID `212601`.

**Действие:** пользователь выполнил `systemctl --user stop llama-server.service`, затем запустил:
```bash
jcode --provider-profile unsloth-qwen run 'Reply exactly: JCODE_UNSLOTH_OK'
```

**Результат:** FAILED. jcode попытался обратиться к `http://127.0.0.1:52681/v1/chat/completions`, но получил TCP Connection refused (os error 111). HTTP-ответа не было; значит этот тест не проверил ключ или заголовок авторизации.

**Отдельный предыдущий результат:** `jcode --provider-profile unsloth-qwen auth-test` показал credential_probe available, но model discovery завершился HTTP 401 `Missing bearer authentication in header`. Это отдельное наблюдение; не смешивать с TCP refusal.

**Статус Unsloth worker:** UNKNOWN / no listener at time of direct jcode run. Причина исчезновения listener не установлена; не приписывать это остановке Hermes service.

**Безопасность:** в присланном unit-файле был виден API key. Значение не записано в журнал и не включается в репозиторий. Рекомендуется заменить/ротировать.

**NEXT_ACTION:** заново загрузить существующую Qwen через Unsloth GUI, определить актуальный порт, затем отдельно повторить прямой jcode smoke test.


---

## 2026-10-31 — исследование интеграции Hermes ↔ Claude Code

**Цель:** выяснить, что даёт официальная интеграция Hermes Agent и Claude Code, и нужна ли она для текущей архитектуры с одной Qwen.

**Проверенные варианты по официальной документации NousResearch:**
- `hermes import-agent claude-code`: перенос части инструкций, разрешений, MCP-серверов и skills из Claude Code в Hermes; это импорт настроек, не live-синхронизация.
- Плагин `mcp-serve`: предоставляет Claude Code и другим MCP-клиентам выбранные функции Hermes, в том числе чтение/отправку сообщений через подключённые к Hermes платформы и дополнительные web/browser/vision/skills/TTS инструменты.
- Anthropic provider: позволяет Hermes обращаться к Claude как к модели; меняет модельный backend, но не объединяет два agent-клиента.
- ACP: подключает Hermes к ACP-совместимому редактору/хосту; это не прямой протокол координации Claude Code и Hermes.

**Решение:** NOT CONFIGURED. Оставить агентов независимыми, поскольку текущая схема общей локальной Qwen уже работает, а Screenlife требует сравнивать самостоятельные маршруты. Один слот `--parallel 1` остаётся общим; интеграция не добавляет пропускной способности. При появлении конкретного сценария первым кандидатом для отдельного теста будет односторонний Claude Code → Hermes через MCP Serve с минимальным набором инструментов.

**Источники:**
- https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp
- https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/import-from-other-agents.md
- https://hermes-agent.nousresearch.com/docs/user-guide/features/acp
- https://hermes-agent.nousresearch.com/docs/integrations/providers

**Дополнительные записи:** `docs/integrations/hermes-claude-code.md`, `SESSION_BOOTSTRAP.md`, `CURRENT_STATE.md`, `NEXT_ACTION.md`.

**Статус:** VERIFIED — документация изучена, решение зафиксировано; runtime-конфигурации не менялись.


---

## 2026-10-31 — Hermes session recovery for SystemRescue translation; context audit correction

Hermes returned historical session IDs, including a parent work session, a translation continuation session and a subagent session named "Перевести оставшиеся 8 файлов SystemRescue". The subagent's last activity was `agent_close`; this is a reported completion state, not proof that its output files remain present or are correct.

The Hermes report's explanation of the 70K limit is not accepted as fact:
- Input/output/cache token counters are cumulative session counters.
- Current Hermes session schema has a separate `last_prompt_tokens` field for the latest actual prompt.
- `_proactive_prune_rearm_tokens` is a pruning/rearm marker, not context occupancy.
- Current Hermes compression facade describes "total ceiling exhausted" as a wall-clock timeout on compression; the code explicitly states no messages were dropped and the turn continues without compression.
- Qwen3.5-9B native context is 262144; later verified Unsloth launch used 160000. Historical launch arguments from Oct 24–28 are still needed.

The report also contains a likely timestamp data issue: session ID prefix `20261024` is paired with a claimed UTC start in 2024. Read the raw record.

Detailed evidence, version caveats and recovery plan: https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md


---

## 2026-10-31 — исследование перехода с Qwen3.5-9B на более крупную модель

**Цель:** подобрать модель для одного общего Unsloth llama-server, которым пользуются Hermes и Claude Code.

**Ограничения:** RTX 3060 12 GB VRAM; системная RAM около 12 GB; swap 4 GB; текущая рабочая архитектура — одна модель, один сервер, два независимых клиента, `--parallel 1`; целевой контекст — 160K. Действующую 9B конфигурацию и файл не трогать.

**Новый кандидат из актуальных рекомендаций Unsloth:** Qwen3.8-27B. Официальная страница Unsloth указывает поддержку Hermes Agent и Claude Code, 27B, native 256K context, agentic coding и nested tool calls. Quant-файлы: UD-IQ3_XXS 10.9 GB, UD-Q3_K_XL 13.1 GB, UD-Q4_K_XL 17.6 GB. Рекомендованный 4-bit вариант требует порядка 17–19 GB total RAM+VRAM; фактическая пригодность на данном хосте зависит от available memory, KV cache и сохранения 160K контекста. Для RTX 3060 выбирать GGUF, не NVFP4 (Unsloth указывает NVFP4 для NVIDIA Blackwell-class устройств).

**Кандидат из ранее использовавшейся коллекции:** Qwen3.6-35B-A3B, 35B total / 3B active, GGUF Unsloth UD-IQ2_XXS около 10.8 GB. Пользователь ранее уже использовал эту модель; наличие файла на диске сейчас не перепроверялось. Двухбитное квантование — существенный компромисс качества.

**Предварительный выбор:** Qwen3.8-27B UD-Q3_K_XL как новая quality-oriented модель для проверки; сначала read-only инвентаризировать локальное наличие Qwen3.6-35B-A3B, чтобы не скачивать то, что уже есть.

**Решение:** RESEARCHED / NOT INSTALLED. Ни одна модель не загружалась, текущая модель не выгружалась, серверы не перезапускались, контекст и маршрутизация не менялись.

**План проверки:** одна модель за раз; сохранить 9B baseline; не снижать 160K без отдельного решения; проверить actual model placement, memory peak, context, speed (prefill и generation отдельно), tool-call reliability и одинаковые сценарии Hermes/Claude Code.

Подробная записка: `docs/model-selection/2026-10-31-upgrade-candidates.md`.
Источники: https://unsloth.ai/models/qwen3.8-27b ; https://huggingface.co/unsloth/Qwen3.8-27B-GGUF ; https://huggingface.co/Qwen/Qwen3.6-35B-A3B ; https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF

**Статус:** VERIFIED для фактов из документации и исторической конфигурации; actual local file inventory и real performance на RTX 3060 ещё не проверялись.


---

## 2026-10-31 — пользователь установил приоритет: аудио прежде новой модели

**Решение пользователя:** сначала завершить аудио/voice работу; к скачиванию и испытанию более крупной модели возвращаться только после этого.

**Решение по конфигурации:**
- Оставить работающую Qwen3.5-9B как baseline.
- Не скачивать Qwen3.8-27B сейчас.
- Не менять модель, endpoint, context 160K или число серверов.
- Причина осторожности: Qwen3.8-27B UD-Q3_K_XL имеет GGUF около 13.1 GB; файл весов сам по себе не включает KV cache, рабочие буферы и overhead. На RTX 3060 12 GB VRAM и около 12 GB системной RAM сохранение контекста 160K может оказаться нереалистичным без детального memory placement.
- Модельный вопрос вернётся после аудио. Тогда сначала проверить свободные ресурсы и локальный файл прежней Qwen3.6-35B-A3B, а не скачивать вслепую.

**Статус:** DECIDED / NO RUNTIME CHANGE. Приоритет добавлен в voice notes, CURRENT_STATE и NEXT_ACTION.


---

## 2026-10-31 — принято постоянное использование benchmark при сравнении моделей

**Уточнение пользователя:** регулярно использовать benchmark / benchmark-models при сравнении моделей и производительности.

**Результат исследования:** публичный skill `benchmark-models` из gstack сравнивает Claude, GPT через Codex CLI и Gemini на одинаковом prompt, измеряя latency, tokens, cost и опционально quality через LLM judge. Это не следует считать готовым локальным benchmark harness для Qwen/Unsloth без проверки custom endpoint support и зависимостей.

Для локального стека закреплён собственный протокол:
- capability benchmarks отдельно от inference/runtime measurements;
- TTFT, prefill tok/s, generation tok/s;
- peak VRAM/RAM, KV placement/offload, actual context;
- tool-call success, correctness, retries и elapsed time;
- одинаковые prompts/client routes и несколько повторов, median/range;
- сохранить raw traces и failed runs.

Стандартный Hermes ecosystem skill `evaluating-llms-harness` может использоваться для отдельных academic/capability evaluations после проверки зависимостей и доступных ресурсов; он не заменяет hardware benchmark и agent task suite.

Документ: `docs/model-selection/BENCHMARK-PROTOCOL.md`.

**Статус:** DECIDED / DOCUMENTED. Никакие skills не устанавливались, модельные серверы не запускались, runtime-конфигурация не менялась.


---

## 2026-10-31 — second Hermes report: partial SystemRescue translation artifact inventory

Hermes reported two files in `/home/oleg/fcm-opencode-test`:
- `Configuring_SystemRescue_sysconfig.md` — 15,020 bytes, SHA-256 `c9e4d2e1351dc182b0032fa97eb3e91a6bb6fe3c9da436f199addaabc232c066`.
- `Downloading_and_burning.md` — 3,008 bytes, SHA-256 `99198e2a28c27f805bfa0bcd8b19e4a30b418d1feee405ec659c90939fac8699`.

Both original and translated paths are reported identical, indicating possible in-place replacement. This has not been verified from filesystem contents; preserve copies before any change. Six other files from the "remaining eight" task were not located in this directory, and their filenames are still unknown.

New context values reported by Hermes:
- config context window: 131072;
- auto-compress threshold: 100000;
- historical llama-server args: `-c 160000`, `--parallel 1`, Flash Attention enabled, context shift disabled, fit enabled and fit target 160000;
- subagent `last_prompt_tokens=32964`.
- cache_read displayed as `61,35`, ambiguous; cache_write 428377.

Do not derive compression_count from cache_write_tokens. The 131072 Hermes context, 100000 threshold and 160000 server context are separate values; this mismatch needs a historical config/runtime audit. The 70K hard model limit remains unsupported. Session `20261024_094607_8dc40d` still has a year discrepancy (ID suggests 2026, reported timestamp says 2024).

Canonical evidence and action plan: https://github.com/convergentaru/pc-rescue-platform/blob/main/docs/SYSTEMRESCUE-TRANSLATION-RECOVERY-AND-CONTEXT-AUDIT-2026-10-31.md


---

## 2026-10-31 — planned comparative HOME audit: Hermes vs Claude Code

**User request:** have both agents inspect the home directory, provide recommendations/reports, and test whether to run together or sequentially.

**Current architecture:** one shared Unsloth llama-server, one Qwen model, `--parallel 1`. Official llama.cpp docs define `--parallel N` as server slot count and expose `/slots` for processing state; `fail_on_no_slot=1` returns 503 when no slot is available. Thus two client agents do not have two simultaneous generation slots in the present setup.

**Plan:**
1. Tiny simultaneous no-tools prompt to observe scheduling/wait/timeout behaviour.
2. Run the same bounded read-only HOME metadata audit sequentially through Hermes and Claude Code.
3. Cross-review the two reports in alternating clients.
4. Publish only a sanitized summary; keep private filenames, sensitive directories and raw personal details out of GitHub.

**Safety:** no file contents, credentials, keys, browser profiles or secret configs are to be read. No writes, cleanup, chmod/chown, installs or downloads. Scan depth and output volume are bounded; large files are reported by metadata only.

Protocol and copy/paste prompt: `docs/operations/HOME-DIRECTORY-AUDIT.md`.

**Status:** PLANNED. No HOME filesystem scan has been run by ChatGPT; no local changes have been made.


---

## 2026-10-31 — расширение HOME audit до длительного агентного задания и Paperclip-пилота

**Пользовательская цель:** перестать ограничиваться короткими проверками и давать Hermes и Claude Code длительную полезную работу; в дальнейшем ставить ночные задания через Paperclip.

**Paperclip research (official docs checked 2026-10-31):**
- Release page shows v2026.1023.0 (released 2026-10-23).
- Built-in adapters include `hermes_local`, `hermes_gateway` and `claude_local`.
- Paperclip agents run in scheduled/assignment/comment/manual heartbeats rather than an endless process; runs have transcripts.
- Hermes adapter supports persistent sessions across heartbeats; documented default timeout 300 sec, configurable `timeoutSec`, `maxIterations`, toolsets and `persistSession`.
- Claude local adapter supports persisted sessions across heartbeats, `timeoutSec` (0 = no process timeout), and `maxTurnsPerRun` (documented default 300).
- Custom Unsloth/Qwen route has not yet been proven through both Paperclip adapters. Claude adapter's env configuration and Hermes local/custom-provider settings must be smoke-tested. Hermes Gateway adapter requires an explicitly enabled Hermes API server; do not assume the existing Gateway UI/service is the same endpoint.

**Long-running HOME audit role split:**
- Hermes: storage/filesystem/model/ISO/archive/cache/build inventory, metadata-only.
- Claude Code: local projects/Git repository workspace map, status and build-folder inventory.
- Then sequential cross-review and a shared evidence-backed action backlog.
- No cleanup, installs, downloads, config changes, file writes or external publishing during initial audit.

**Scheduling constraint:** current Unsloth has `--parallel 1`; agents must be staggered. A simultaneous heartbeat does not create extra model capacity.

**Safety:** sensitive directories and file contents are excluded; report publication must be sanitized. Overnight autonomy remains disabled until adapter routing, checkpoint/resume and Stop controls pass tests.

**Docs:** `docs/operations/LONG-RUNNING-AGENT-WORK-PAPERCLIP.md`, expanded `docs/operations/HOME-DIRECTORY-AUDIT.md`.

**Status:** RESEARCHED / DESIGNED / NOT RUN. No Paperclip install, agent adapter config or local HOME scan has been performed by ChatGPT.


---

## 2026-10-31 — Unsloth Qwen 160K launch and direct API verification; Hermes service recovery checkpoint

### Goal
Restore the intended shared-model topology: one Qwen3.5-9B model served by Unsloth; existing Hermes and Claude Code remain separate clients of that endpoint.

### Unsloth launch — VERIFIED
The user executed:

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
- Model loaded; Unsloth reported the llama-server ready.
- Client endpoint: `http://127.0.0.1:8888/v1`.
- Internal llama-server port: `53815` for this run; dynamic and not a client endpoint.
- `GET /v1/models` returned HTTP 200. Qwen3.5-9B-Q4_K_M was loaded; configured context 160000; reported native/max context 262144.
- A real Chat Completions request returned HTTP 200 and the expected Russian answer.
- A memlock/RLIMIT warning appeared in the launch log, but model loading and API generation succeeded. No limit changes were made.

**Status:** VERIFIED for Unsloth model loading and direct API generation.

### Hermes provider configuration — OBSERVED
The inspected Hermes config already selects:
- provider `custom`;
- `http://127.0.0.1:8888/v1`;
- model `Qwen3.5-9B-Q4_K_M`;
- `chat_completions`;
- context `160000`.

The configured environment variable `HERMES_CUSTOM_127_0_0_1_8888_API_KEY` was confirmed present in `~/.hermes/.env`. Its value is not recorded. Piper TTS configuration was present; no voice test was part of this step.

**Status:** OBSERVED. Config correctness is established, but this is not a successful Gateway request test.

### systemd status — OBSERVED
User ran `systemctl is-active` for both services and received:
- `hermes-gateway.service`: `inactive`.
- `llama-server.service`: `inactive`.

The legacy `llama-server.service` must stay inactive to prevent a second model server. The existing Hermes Gateway needs diagnosis. Its unit file and recent journal have not yet been inspected. No service start, stop, or config edit was performed in this checkpoint.

### Next diagnostic action
Read-only inspection of:
`systemctl status hermes-gateway.service --no-pager -l`,
`systemctl cat hermes-gateway.service`, and
`journalctl -u hermes-gateway.service -n 40 --no-pager`.

Do not start the old `llama-server.service`. Do not edit Hermes config or systemd units until the Gateway's actual unit and failure/stop reason are known.


---

## 2026-10-31 — Hermes Gateway unit not found in system scope; scope check correction

**User command:** inspected `systemctl status`, `systemctl cat` and `journalctl` for `hermes-gateway.service` without `--user`.

**Exact result:**
```text
Unit hermes-gateway.service could not be found.
No files found for hermes-gateway.service.
-- No entries --
```

**Interpretation:** the system systemd manager does not know this unit. This does not prove that the Gateway is uninstalled; Hermes documents a user-scope service as the normal Linux setup, with service files under `~/.config/systemd/user`. The previous unqualified `systemctl is-active` response of `inactive` was not sufficient to establish the Gateway state.

**Research:** current official Hermes Messaging Gateway documentation lists:
- `hermes gateway status` to inspect the default service;
- `systemctl --user` / `journalctl --user -u hermes-gateway` for the default Linux user service;
- `hermes gateway status --system` and system journal only for an explicit `--system` installation.

**Status:** OBSERVED (system-scope unit not found); actual Gateway process/service scope remains UNKNOWN.

**Next diagnostic:** execute `hermes gateway status`, followed by read-only `systemctl --user status/cat` and `journalctl --user`. Do not install/start/reconfigure the Gateway until this is understood.

Source: https://hermes-agent.nousresearch.com/docs/user-guide/messaging


---

## 2026-10-31 — definitive Hermes Gateway status from user systemd scope

**Correction:** Earlier interpretation that Hermes Gateway was inactive was wrong. The earlier `systemctl` query omitted `--user` and queried the system manager, while this host's actual Gateway is installed as a user service.

**User-provided evidence:**
- `hermes gateway status`: `User gateway service is running`.
- Unit loaded from `/home/oleg/.config/systemd/user/hermes-gateway.service`.
- `systemctl --user status`: `active (running)`, `enabled`.
- Started 2026-10-31 13:39:29 MSK; Main PID 1822.
- systemd linger enabled.
- Child processes included MCP server PID 4378 and MCP death supervisor PID 4379.
- User unit inventory showed `hermes-gateway.service enabled` and `hermes-qwen35.service disabled`.

**Application health warnings:**
- Gateway startup says `No messaging platforms enabled.`
- WhatsApp is enabled but no profile provides a bot credential; WhatsApp is not being served / not paired.
- No environment user allowlists configured; platform defaults to pairing/allowlist policies.
These are messaging-platform setup/availability warnings. They do not indicate that the Gateway daemon itself is stopped.

**Historical inference error in prior Gateway journal:**
At 13:35:54 the earlier Gateway process attempted provider `custom`, base URL `http://127.0.0.1:8888/v1`, model `Qwen3.5-9B-Q4_K_M`, and ended after 3 attempts with `APIConnectionError`. That process was stopped with SIGTERM at 13:38:58; a new Gateway process started at 13:39:29. The older connection failure occurred before the latest confirmed Unsloth direct API success and is not proof that the current endpoint is failing.

**Status:**
- Existing Hermes Gateway daemon: VERIFIED RUNNING as user service.
- Gateway messaging platforms: OBSERVED NONE enabled; WhatsApp incomplete/unpaired.
- Hermes Gateway → Unsloth fresh generation after current Unsloth startup: NOT YET VERIFIED.
- No service start/restart, install, or unit modification was performed in this step.

**Next:** one real one-shot Hermes CLI request through the running Gateway, using the already configured Custom provider, then record the exact response/error. Do not repeat system-scope service checks and do not restart the Gateway.


---

## 2026-10-31 — successful Hermes Custom → Unsloth smoke test

**User-provided result:** Hermes resumed session
`local-bd95986af8a0ecfcfc909532acc3d5ae08730dee0c92b157d4e21eba2c508371`.

The restored model was:
`Qwen3.5-9B-Q4_K_M (custom:unsloth-qwen-160k)`.

The previous conversation showed the exact test:
```text
User: Ответь строго одной строкой: HERMES_UNSLOTH_OK
Hermes: HERMES_UNSLOTH_OK
```

**Result:** the Hermes CLI successfully generated the expected response via its selected Custom provider. This is a functional test of the Hermes CLI → Custom provider → Unsloth route.

**Scope limitation:** this does not test inbound requests from Telegram/WhatsApp or other messaging adapters through the Gateway. The Gateway daemon itself was separately confirmed active as a user systemd service; its startup logs said no messaging platforms were enabled, and WhatsApp was not paired/configured.

**Status:** VERIFIED for Hermes CLI inference through Custom/Unsloth. Messaging-platform integration remains NOT CONFIGURED / NOT TESTED. No service restart or configuration change was required for this test.

**Next:** fresh Claude Code smoke test against the already running Unsloth endpoint; then one process/model inventory to ensure no second inference server appeared.


---

## 2026-10-31 — Claude Code → Unsloth functional smoke test passed

**Launch command executed by user:**
```bash
unsloth start claude --no-serve
```

**Claude Code output:**
```text
Claude Code v2.1.286
Qwen3.5-9B-Q4_K_M · API Usage Billing

User: Ответь строго одной строкой: CLAUDE_UNSLOTH_OK

Claude: CLAUDE_UNSLOTH_OK

Crunched for 21s · done 14:36
```

**Result:** exact expected response received. Claude Code v2.1.286 successfully generated through the Unsloth `--no-serve` route using Qwen3.5-9B-Q4_K_M.

**Combined result:** both clients passed independent functional text tests:
- Hermes CLI Custom profile `custom:unsloth-qwen-160k` → `HERMES_UNSLOTH_OK`.
- Claude Code via `unsloth start claude --no-serve` → `CLAUDE_UNSLOTH_OK`.

**Status:** VERIFIED for both client generation paths. This does not by itself establish that the exact same single llama-server process was the only inference process after both launches; perform one read-only exact-name process inventory next. Do not restart services or relaunch models.


---

## 2026-10-31 — final inventory found two llama-server processes (one-server invariant not met)

**User command:**
```bash
pgrep -xc llama-server
for pid in $(pgrep -x llama-server); do
  ps -ww -p "$pid" -o pid=,ppid=,comm=,args=
done
```

**Observed count:** 2.

### Process A — legacy Hermes model server
- PID: 1823.
- PPID: 1645 (user systemd manager).
- Executable: `/home/oleg/.hermes/tools/llamacpp-cuda-11370-linux-x64/llama-server`.
- Port argument: `18434`.
- Arguments include `--models-max 1 --models-autoload`, `--metrics`, `--slots`, `--no-ui`, and Hermes preset file `/home/oleg/.hermes/runtimes/llamacpp/presets.ini`.
- Command line includes a credential argument; its value is intentionally omitted from project documentation.
- Likely legacy Hermes model-management server, but actual owning unit and loaded-model state are not yet verified.

### Process B — intended Unsloth server
- PID: 10358.
- PPID: 10257.
- Executable: `/home/oleg/.unsloth/llama.cpp/llama-server`.
- Model: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- Internal port: `53815` (dynamic).
- `--parallel 1`; context `-c 160000`.
- This is the currently verified server used by Unsloth API, Hermes CLI and Claude Code.

**Conclusion:** two server processes are running. This disproves the earlier assumption that the legacy Hermes server was stopped. It does not yet prove two model weight sets are currently loaded: process A uses model presets with `--models-autoload`, and its actual loaded-model state remains unknown.

**Next read-only diagnosis:**
- Run `systemctl --user status 1823 --no-pager -l` to map the PID to its owning unit. systemd's `status PID` syntax is documented to show the unit containing that PID.
- Inspect the identified unit status/cat/journal.
- Check current model state on legacy port 18434 without printing or copying the API key.
- Do not kill PID 1823 or stop the unit yet. Preserve PID 10358/Unsloth.


---

## 2026-10-31 — identified owner of legacy port 18434

**User-provided result:** `systemctl --user status 1823` mapped PID 1823 to `llama-server.service`.

Observed:
- Unit path: `~/.config/systemd/user/llama-server.service`.
- Active (running), enabled; Main PID 1823.
- Process is Hermes-bundled llama.cpp on port 18434.
- Command uses `--models-max 1 --models-autoload`, Hermes model presets.
- Startup log explicitly states: `starting server in router mode. models will be automatically loaded on-demand`.
- Memory shown for the router process: 11.4M current, peak 242.3M.
- `hermes-qwen35.service` is separately loaded but `inactive (dead)`, disabled; it is described as a Qwen3.5-4B server.

**Interpretation:** PID 1823 is the legacy Hermes router, not the active Unsloth Qwen process. Low memory and router-mode startup suggest it may have no loaded child model; this remains an inference until its `GET /models` state is checked.

**Status:** owner unit VERIFIED; active loaded-model inventory on port 18434 UNKNOWN; no service was stopped.


---

## 2026-10-31 — legacy Hermes router confirmed empty; safe deactivation planned

**User's read-only router query** against port 18434:
- `GET /models`: seven preset models returned, every model status `unloaded`.
- `GET /v1/models`: same seven presets, every model status `unloaded`.
- The checked list includes `Qwen3.5-9B-Q4_K_M`, also unloaded.

**Unit configuration:**
- `llama-server.service` in the user systemd manager.
- Starts Hermes-bundled llama.cpp in router mode on 127.0.0.1:18434.
- `--models-max 1 --models-autoload`.
- `Restart=on-failure`; `WantedBy=default.target`.
- No loaded model is held by this router according to its own API.

**Other service:** `hermes-qwen35.service` is inactive/dead and disabled; unrelated to PID 1823.

**Interpretation:** two server processes were present, but only the Unsloth server had a loaded model. The 18434 router is idle and unnecessary for the target architecture where Hermes Custom and Claude Code both connect to Unsloth. The existing Gateway user unit does not declare a dependency on `llama-server.service`; Hermes' current configured provider points to Unsloth and has passed its direct smoke test.

**Planned action:** `systemctl --user disable --now llama-server.service`, which stops the idle router and removes its automatic start link. This preserves the unit file and model presets. It is a reversible service-state change, not deletion. This command has not yet been run by the user.

**Post-change acceptance:** check old unit inactive/disabled; Gateway user service still active; Unsloth API remains functional; exact `llama-server` process count is 1. Do not stop Unsloth.


---

## 2026-10-31 — disabled idle legacy Hermes router; one-server invariant achieved

**User-executed command:**
```bash
systemctl --user disable --now llama-server.service
```

**Post-change user-provided output:**
```text
=== LEGACY SERVER ===
inactive
disabled
=== HERMES GATEWAY ===
active
=== LLAMA SERVER COUNT ===
1
```

**Result:**
- Legacy Hermes router on port 18434 is stopped and disabled from automatic user-service startup.
- Hermes Gateway remains active.
- Exactly one llama-server process remains; this is the intended Unsloth Qwen process.
- No model files, preset files or unit files were deleted. The service change is reversible.
- Both Hermes CLI and Claude Code had already passed their functional smoke tests through Unsloth before this deactivation.

**Status:** VERIFIED for service deactivation, Gateway preservation and process count = 1.

**Remaining:** one fresh direct Unsloth API generation test after disabling the legacy router. Then the manual post-reboot startup sequence can be consolidated. A real reboot test remains outstanding.
