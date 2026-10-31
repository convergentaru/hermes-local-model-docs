# AGENTS.md — общие инструкции для локальной AI-лаборатории

Это общий репозиторий памяти пользователя для локального AI-стека. Рабочая тройка клиентов: Hermes, OpenCode и jcode. Дополнительный компонент GBrain используется как вспомогательный слой памяти.

## Обязательная загрузка контекста при старте

Перед любой работой в этом репозитории:
1. Прочитай `SESSION_BOOTSTRAP.md` — самый свежий краткий снимок системы и текущей незавершённой задачи.
2. Прочитай `docs/operations/SHARED-MEMORY-PROTOCOL.md`.
3. Прочитай `CURRENT_STATE.md` и `NEXT_ACTION.md`.
4. Открой связанные документы только по необходимости.

Не проси пользователя повторять сведения, уже сохранённые здесь. Не начинай заново завершённые этапы.

## Правила технической работы

- Перед выдачей технических рекомендаций самостоятельно изучай официальную документацию, HELP/CLI reference, GitHub source, Issues, Pull Requests и профильные обсуждения. Сопоставляй независимые источники и проверяй совместимость с фактической версией и конфигурацией.
- Не выдумывай команды, параметры, пути, порты или состояние процессов.
- Разделяй `VERIFIED`, `OBSERVED`, `FAILED`, `PLANNED` и `UNKNOWN`. Запуск процесса или открытый порт ещё не доказывает рабочий inference.
- Двигайся по схеме: один контролируемый шаг → один функциональный тест → запись фактического результата.
- Не запускай две копии одной большой GGUF на RTX 3060 12 GB одновременно без проверки ресурсов.
- Не меняй параметры контекста, offload, parallel и KV cache по догадке. Учитывай RAM и VRAM.
- Перед редактированием существующих конфигов сохрани исходные значения/backup.
- После значимого действия обнови `EXPERIMENT_LOG.md`, `CURRENT_STATE.md` и `NEXT_ACTION.md`, если они относятся к изменившемуся состоянию.

## Обязательное правило GitHub для всех проектов

Пользователь поручил фиксировать всю существенную проектную работу на GitHub. Это постоянное правило, не ограниченное этим репозиторием.

- Каждый существенный этап, тест, результат, ошибка, решение и следующий шаг должен попасть в GitHub-репозиторий соответствующего проекта.
- Записывай промежуточные результаты и неудачные попытки, а не только красивый финальный итог.
- Обновляй журнал, текущее состояние и next action так, чтобы работу можно было продолжить без повторного опроса пользователя.
- Используй отдельный существующий репозиторий проекта; не смешивай несвязанные проекты.
- Не ограничивайся обещанием записать: после записи проверь commit и дай пользователю ссылку.
- Не публикуй стенограмму каждой бытовой реплики; сохраняй полную историю значимой работы, включая важные уточнения пользователя.
- Если GitHub недоступен или подходящего репозитория нет, прямо сообщи об ограничении. Не утверждай, что материал опубликован.

## Секреты

Никогда не коммить API keys, bearer tokens, пароли, реальные значения из `.env` / `*.env`, приватные заголовки или полные секретные конфиги. В документации оставляй только безопасные пути, имена переменных и несекретные значения.


## Benchmarking requirement

For model selection, upgrades, quantization or inference tuning, use `docs/model-selection/BENCHMARK-PROTOCOL.md`. Compare actual TTFT, prefill/generation throughput, peak VRAM/RAM, context stability, tool-call success and task correctness. Keep standardized model capability benchmarks separate from local runtime measurements and agent workflow tests. Never recommend a larger model from parameter count or GGUF file size alone.


## Long-running task execution and Paperclip

When work spans multiple sessions, split it into explicit phases with durable checkpoints. A task is not complete merely because one heartbeat or CLI session ended. Record completed phases, next action, artifact paths, and status. For Paperclip tasks, update issue/task status and comments before a heartbeat ends; resume persistent sessions rather than starting again.

The local workstation currently has one Unsloth inference slot. Stagger Hermes and Claude Code heartbeats for long model-intensive jobs; do not schedule them simultaneously expecting parallel generation. Before unattended overnight work, verify adapter routing to the custom local endpoint, task persistence, timeout/Stop, and sensitive-path exclusions.

For the approved HOME audit, follow `docs/operations/LONG-RUNNING-AGENT-WORK-PAPERCLIP.md`. Initial work is read-only; no automatic cleanup.
