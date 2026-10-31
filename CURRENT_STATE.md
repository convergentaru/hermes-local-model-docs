# CURRENT_STATE — локальная AI-инфраструктура

Последнее обновление: 2026-10-31  
Главная документация: `convergentaru/hermes-local-model-docs`  
Общий протокол: [docs/operations/SHARED-MEMORY-PROTOCOL.md](docs/operations/SHARED-MEMORY-PROTOCOL.md)

> Это снимок состояния на указанную дату, а не обещание, что сервисы продолжают работать сейчас. Статусы отражают только подтверждённые сведения.

## Цель текущего этапа

Восстановить запуск Claude Code через Unsloth Desktop/Studio с одной копией Qwen3.5-9B. Не запускать параллельную копию модели в Hermes. Сохранить существующие настройки и не переустанавливать компоненты без необходимости.

## Компьютер

- Ubuntu 26.
- NVIDIA GeForce RTX 3060, 12 GB VRAM.
- Системная RAM: около 12 GB.
- Swap: 4 GB.
- Основной язык окружения: русский.

## Модель и расположение

- Целевая модель: `Qwen3.5-9B-Q4_K_M.gguf`.
- Путь, использовавшийся в последнем запуске: `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`.
- Наличие файла и его метаданные в ходе текущей сессии заново не проверялись.
- Не переносить и не удалять модель без отдельного подтверждения.

## Состояние на 2026-10-31

| Компонент / факт | Статус | Примечание |
|---|---|---|
| Остановка AI/model процессов | OBSERVED | Пользователь сообщил, что VRAM после остановки занята примерно на 0,5%. |
| Unsloth Studio | UNKNOWN | После остановки процессов не подтверждён повторный запуск. |
| Qwen3.5-9B в Unsloth | UNKNOWN | Требуется загрузка одной модели через GUI и проверка ответа. |
| Hermes model server | STOPPED (по сообщению пользователя) | В этой рабочей сессии не должен запускаться параллельно с Unsloth. |
| Claude Code | NOT RUNNING / UNKNOWN | Требуется подключить после успешного теста модели через Unsloth. |
| Unsloth API :8888 | HISTORICAL | Ранее использовался как API/входная точка Studio. Текущее состояние не проверено. |
| Unsloth worker :33085 | HISTORICAL | Ранее наблюдался как worker модели. Порт может изменяться. |
| Hermes llama-server :46223 | HISTORICAL | Ранее был второй копией Qwen; не запускать одновременно с Unsloth. |

## Исторически наблюдавшаяся проблема

Ранее одновременно работали две копии Qwen3.5-9B:
- Hermes `llama-server` на порту 46223, около 7590 MiB VRAM;
- Unsloth worker на порту 33085, около 3726 MiB VRAM.

Общая занятость GPU достигала примерно 11842 MiB из 12288 MiB. Это объясняет дефицит VRAM в том снимке. Порты являются историческими наблюдениями, а не фиксированными значениями.

## Ошибка последней попытки

Команда:

```bash
unsloth start claude --model /home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf --max-seq-length 65536
```

Результат:

```text
Error: Input must be provided either through stdin or as a prompt argument when using --print
```

Статус: FAILED. Не повторять как проверенный способ запуска. Требуется восстановить запуск через GUI Unsloth и отдельно правильный способ подключения Claude Code.

## Известные исторические настройки Unsloth

Для более раннего запуска Qwen3.5-9B в Unsloth наблюдались:
- контекст 65 536;
- parallel 4;
- Flash Attention On;
- Context Shift Off;
- KV Unified On;
- Fit On;
- Context Checkpoints 5;
- Reasoning Off;
- Load Mode mmap+mlock.

Эти параметры являются историческими сведениями и требуют сверки с сохранённым профилем GUI. Не считать их полностью восстановленной текущей конфигурацией.

## Известные параметры Claude Code

В прежнем профиле Unsloth/Claude наблюдались:
- `ANTHROPIC_BASE_URL=http://127.0.0.1:8888`;
- `ANTHROPIC_MODEL=Qwen3.5-9B-Q4_K_M`;
- `CLAUDE_CODE_MAX_CONTEXT_TOKENS=65536`;
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90`;
- `CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384`.

Считать историческим профилем, пока он не будет прочитан из локальных настроек и протестирован. Секреты и API keys не документировать.

## Что уже есть в документации

- [Unsloth Desktop: общая библиотека, CUDA и custom llama.cpp](docs/unsloth/studio-model-library-and-custom-llama-cpp.md)
- [Архитектура локального AI-стека](docs/architecture/current-local-ai-stack.md)
- [Диагностика локального AI-стека](skills/local-ai-stack-diagnostics/SKILL.md)
- [Project Atlas](docs/hermes/project-atlas/START.md)

## Правило следующего шага

Следующий шаг — не терминальная команда запуска Claude. Сначала открыть Unsloth Desktop/Studio, проверить существующий профиль, выбрать одну Qwen3.5-9B GGUF, загрузить её с параметрами из профиля и выполнить короткий тест в самом приложении. Только после успешного ответа подключать Claude Code.


---

## Дополнение: снимок 2026-10-31 — Hermes + Unsloth + три agent-клиента

Актуальная сводка и хронология этой сессии: [SESSION_BOOTSTRAP.md](SESSION_BOOTSTRAP.md). Этот блок новее первоначального описания портов выше.

- Рабочая тройка клиентов, которую сейчас рассматриваем: Hermes, OpenCode и jcode. GBrain — вспомогательная система памяти; не считать его подтверждённым четвёртым model-клиентом.
- Hermes model server по переданному systemd unit использует `127.0.0.1:18434`; Gateway использует этот адрес из `~/.hermes/config.yaml`.
- Hermes `llama-server.service` был остановлен пользователем во время теста jcode. Обратный запуск в этой сессии не подтверждён.
- Unsloth worker на `52681` был LISTEN с PID `212601` в одном снимке, но при последующем jcode run соединение уже отклонялось. Текущий порт неизвестен.
- jcode v0.99.1, profile `unsloth-qwen`, модель `Qwen3.5-9B-Q4_K_M`. Auth-test ранее получил HTTP 401 Missing bearer; последующий прямой run получил TCP Connection refused. Это разные этапы и разные отказы.
- Не считать jcode подключённым к модели до успешного фактического ответа `JCODE_UNSLOTH_OK`.
- Секрет из присланного Hermes unit намеренно не сохранён; его следует ротировать.

