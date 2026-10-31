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
