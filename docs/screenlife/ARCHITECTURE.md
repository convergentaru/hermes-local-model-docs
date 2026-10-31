# Архитектура: один inference engine, два агента

## Фактическая схема после настройки 31.10.2026

```text
                         ┌──────────────────────────────┐
                         │ Qwen3.5-9B-Q4_K_M.gguf       │
                         │ один загруженный экземпляр   │
                         │ context 160000 / parallel 1  │
                         └──────────────┬───────────────┘
                                        │
                              llama-server (Unsloth)
                              внутренний порт динамический
                                        │
                              Unsloth API :8888
                               127.0.0.1
                                 /       \
                                /         \
                     OpenAI Chat          Anthropic Messages
                           /                 \
                    Hermes Gateway        Claude Code
```

## Подтверждённые параметры

| Компонент | Значение |
|---|---|
| Модель | `/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf` |
| Unsloth CLI | `2026.10.11` |
| API host/port | `127.0.0.1:8888` |
| Model context | `160000` |
| Parallel slots | `1` |
| Hermes provider | Custom OpenAI-compatible endpoint |
| Hermes API mode | Chat Completions |
| Hermes endpoint | `http://127.0.0.1:8888/v1` |
| Hermes model ID | `Qwen3.5-9B-Q4_K_M` |
| Hermes local runtime | `local_runtime.enabled=false` |
| Claude Code | `2.1.286` |
| Claude Code base URL | `http://127.0.0.1:8888` |
| Claude Code launch | `unsloth start claude --no-serve` |

## Проверенное состояние в конце сессии

- Один процесс `llama-server` — Unsloth.
- Внутренний порт в той сессии: `55831`. Это динамический порт, его нельзя жёстко зашивать в сценарии повторного запуска.
- Unsloth API `:8888` отвечал HTTP 200.
- Порт старого Hermes server `:18434` перестал слушать после отключения local runtime и перезапуска Gateway.
- Hermes Gateway после перезапуска ответил на контрольный запрос.
- Claude Code получил ответ от Qwen через Anthropic-совместимый маршрут Unsloth.

## Один слот — последовательная нагрузка

У сервера `--parallel 1`. Это один активный inference slot. Hermes и Claude Code могут использовать одну модель, но конкурирующие запросы будут ожидать освобождения слота; это не два параллельно исполняемых потока генерации.

Для честных сравнений запускать задания последовательно либо явно отмечать пересечение запросов.

## Что нельзя путать

- Unsloth API wrapper на :8888 и внутренний `llama-server` — разные процессы, но не две копии модели.
- Два агента — не две модели.
- Один слот — не отсутствие двух подключённых клиентов.
- `--fit-target 548` в команде llama-server — не размер контекста. Фактический контекст задаётся `-c 160000`.
- PID и внутренний порт меняются при новом запуске.
