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
