# SESSION_BOOTSTRAP — актуальная память локальной AI-лаборатории и Screenlife

Последнее обновление: 2026-10-31 (Europe/Berlin).  
Источник проектных фактов: этот репозиторий и отдельные репозитории соответствующих проектов.  
Это снимок последней подтверждённой конфигурации, а не live-мониторинг.

## Правило работы

Пользователь поручил фиксировать на GitHub всю существенную проектную работу: исходные условия, решения, команды, тесты, ошибки, промежуточные факты, ограничения и следующий шаг. Использовать репозиторий соответствующего проекта. После существенного результата обновлять журнал и текущий статус. Не публиковать секреты. Подробности: [общий протокол памяти](docs/operations/SHARED-MEMORY-PROTOCOL.md).

Перед продолжением:
1. Прочитать этот файл, `AGENTS.md`, `docs/operations/SHARED-MEMORY-PROTOCOL.md`.
2. Прочитать `CURRENT_STATE.md`, `NEXT_ACTION.md` и профильный документ.
3. Не повторять завершённые этапы и не принимать исторические порты/PID за текущие.

## Компьютер

- Ubuntu 26, i3 X11.
- NVIDIA GeForce RTX 3060, 12 GB VRAM.
- Системная RAM около 12 GB, swap 4 GB.
- Модель: `Qwen3.5-9B-Q4_K_M.gguf`.
- Путь: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.

## Последняя подтверждённая архитектура: одна модель, два агента

Дата фиксации: 2026-10-31.

**Один общий Unsloth llama-server**, одна загруженная копия Qwen3.5-9B; два разных клиента:
- Hermes использует OpenAI-compatible Chat Completions API.
- Claude Code использует Anthropic-compatible API.
- Оба направлены в Unsloth API wrapper на `127.0.0.1:8888`.
- `--parallel 1`: один слот, запросы агентов конкурируют за слот и обслуживаются последовательно. Это не одновременная параллельная генерация.

### Проверенные параметры Unsloth

CLI: `2026.10.11`.

Команда запуска:
```bash
unsloth run \
  --model "/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf" \
  --context-length 160000 \
  --parallel 1 \
  --gpu-memory-mode manual \
  --api-only \
  --host 127.0.0.1 \
  --port 8888
```

Фактически наблюдались:
- API wrapper: `127.0.0.1:8888`.
- Внутренний динамический порт llama-server в последнем снимке: `55831` (не фиксировать в скриптах).
- PID llama-server в последнем снимке: `259764` (исторический PID, может измениться).
- llama-server получил `--parallel 1` и `-c 160000`.
- Один процесс llama-server держал модель; не запускать вторую копию Qwen.

### Hermes

- Custom endpoint: `http://127.0.0.1:8888/v1`.
- Compatibility: `Chat Completions`.
- Model ID: `Qwen3.5-9B-Q4_K_M`.
- Context: `160000`.
- Display name: `Unsloth Qwen 160K`.
- Reasoning disabled.
- Для CLI точное имя модели в этой конфигурации: `/model custom:Qwen3.5-9B-Q4_K_M`.
- Для прекращения автоподъёма старого Hermes llama-server установлено `local_runtime.enabled false`; Gateway перезапущен и отвечает через общий Unsloth endpoint.
- Старый Hermes model server на `18434` после этого не поднимался в последней проверке.

### Claude Code

- Версия: `2.1.286`.
- Запуск к уже работающему Unsloth: `unsloth start claude --no-serve`.
- `--no-serve` не запускает вторую модель/второй llama-server.
- `/status` подтвердил Qwen3.5-9B и Anthropic base URL `http://127.0.0.1:8888`.

### Функциональные проверки

- OpenAI-compatible запрос через Unsloth: HTTP 200, ответ `ГОТОВО`, first byte около 3.41 s.
- Hermes CLI: новая сессия после переключения модели ответила `ГОТОВО`.
- Hermes Gateway ответил `GATEWAY`.
- API/health на живых endpoint отвечали HTTP 200.
- В последней полной проверке найден ровно один llama-server; порт `18434` отсутствовал.
- Эти результаты подтверждают работоспособность на момент теста 2026-10-31; не считать PID/динамический порт постоянными.

Не менять контекст, модель, слоты, маршрутизацию или runtime без конкретной причины и теста. Не предлагать рестарт работающего Gateway без причины.

## Screenlife: два агента, одна модель

Проект создан в репозитории `convergentaru/hermes-local-model-docs`, раздел `docs/screenlife/`.

- [Главная страница](docs/screenlife/README.md)
- [Runbook](docs/screenlife/RUNBOOK.md)
- [Architecture](docs/screenlife/ARCHITECTURE.md)
- [Production/capture](docs/screenlife/PRODUCTION.md)
- [Сессия 2026-10-31](docs/screenlife/sessions/2026-10-31/README.md)

Коммиты публикации проекта: `70cfe6a`, `90c2ad0`, `4efd7fa`. Последний SHA проекта на момент публикации: `4efd7fa63a2e8a74f05908ec85694d1eb5f5dae8`.

Важный принцип: реальные действия и ответы агентов, не инсценировка. Один слот означает последовательное выполнение запросов. Сырые screen recordings и полные terminal logs ещё не загружены; существующие архивы помечают повреждённые/неполные копии результатов.

## SystemRescue / перевод справки

Отдельная задача, не смешивать со Screenlife:
- проект PC rescue USB на основе SystemRescue 13.02;
- ранее извлечены оригинальные help-материалы в `systemrescue-help-original`;
- цель — подготовить русскоязычную справку и в перспективе русскую help ISO;
- Hermes в текущем разговоре не вспомнил задачу и выдал неподтверждённое утверждение о жёстком лимите 70K;
- известная конфигурация Hermes Custom была установлена на 160000 tokens. Максимальное окно модели и фактический активный контекст/компрессия — разные понятия;
- пользователю был передан prompt для `session_search` по SystemRescue / `systemrescue-help-original` / перевод и проверки `/usage`. Ждём фактический отчёт Hermes; перевод повторно не запускать до проверки прежней сессии/результата.

## Статусы и оговорки

- `VERIFIED`: проверено фактическим тестом.
- `OBSERVED`: замечено в логе/снимке, но не полностью протестировано.
- `FAILED`: тест выполнен и завершился ошибкой.
- `PLANNED`: ещё не выполнено.
- `UNKNOWN`: состояние не установлено.
- `SUPERSEDED`: историческое состояние, заменённое более новым.

Контекст 160K — настроенное окно/лимит запроса, а не обещание, что все старые реплики постоянно находятся в активном prompt. Hermes compression может суммировать старые сообщения; для восстановления надо использовать session search/archive и telemetry, а не выдумывать универсальный hard cap.

## Следующее действие

См. [NEXT_ACTION.md](NEXT_ACTION.md). Не выполнять дополнительные изменения инфраструктуры без необходимости: последняя схема общего Unsloth endpoint уже прошла функциональные тесты.


---

## Latest superseding update — 2026-10-31

This section supersedes older snapshots elsewhere in this file that describe two independent llama-server processes or legacy ports as the intended current architecture.

### Current shared-model setup (verified on 2026-10-31)
- One Unsloth `llama-server`, one loaded `Qwen3.5-9B-Q4_K_M.gguf`.
- Unsloth API wrapper: `127.0.0.1:8888`.
- Launch context: 160000; `--parallel 1`.
- Hermes uses Custom OpenAI Chat Completions at `http://127.0.0.1:8888/v1`.
- Claude Code 2.1.286 uses Anthropic-compatible API at `http://127.0.0.1:8888`, started with `unsloth start claude --no-serve`.
- Hermes `local_runtime.enabled false`; the old Hermes model server on `:18434` was absent in the last full check.
- Functional tests passed for Unsloth API, Hermes CLI, Hermes Gateway and Claude Code status. See `docs/screenlife/RUNBOOK.md` and `docs/screenlife/sessions/2026-10-31/README.md`.
- PID and internal llama-server port are dynamic; never hardcode them.
- One slot means requests from agents are serialized. Do not describe this as parallel inference.

### Hermes ↔ Claude Code integration decision
The official options and rationale are documented in `docs/integrations/hermes-claude-code.md`. Decision: **do not install additional integration yet**. Keep agents independent for Screenlife comparison. Evaluate one-way MCP Serve only when a concrete cross-agent use case appears.

### SystemRescue translation remains a separate pending task
Do not mix it with Screenlife. The likely task is Russian translation of SystemRescue 13.02 help material previously extracted to `systemrescue-help-original`. Await the result of Hermes `session_search` for the original task/session and `/usage` compression telemetry. Do not rerun translation until the previous session/result is recovered.
