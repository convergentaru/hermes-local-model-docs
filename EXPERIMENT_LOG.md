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
