# Сессия Screenlife — 31 октября 2026

Первая сравнительная сессия двух агентов на одной локальной модели Qwen3.5-9B.

## Участники и среда

- Hermes CLI/Gateway — Custom OpenAI-compatible endpoint через Unsloth.
- Claude Code 2.1.286 — Anthropic-compatible endpoint через Unsloth.
- Модель: Qwen3.5-9B-Q4_K_M.gguf.
- Один Unsloth llama-server; context 160000; parallel 1.
- Unsloth API: 127.0.0.1:8888.
- Hermes local runtime отключён; Gateway перезапущен после изменения настройки.

## Хронология настройки

1. Запущен Unsloth API-only на :8888.
2. Qwen3.5-9B загружена; в логах: context 160000, parallel 1, internal port 55831.
3. Claude Code запущен с `unsloth start claude --no-serve`.
4. `/status` подтвердил Claude Code 2.1.286, Anthropic base URL :8888 и Qwen model ID.
5. Реальный запрос к OpenAI-compatible endpoint вернул HTTP 200 и `ГОТОВО`; first byte 3.413271 s, total 3.413405 s.
6. Hermes Custom endpoint настроен на `http://127.0.0.1:8888/v1`, Chat Completions, model `Qwen3.5-9B-Q4_K_M`, context 160000, reasoning disabled.
7. Hermes session switched to exact model ID. Новая сессия ответила `ГОТОВО`.
8. Hermes Gateway после перезапуска ответил `GATEWAY`.
9. Было обнаружено автоматическое восстановление отдельного Hermes llama-server на :18434.
10. Выполнено `hermes config set local_runtime.enabled false`.
11. Выполнено `hermes gateway restart --detach`; Gateway успешно перезапустился.
12. Финальный процессный вывод показал только Unsloth llama-server PID 259764; Unsloth API на :8888 ответил HTTP 200.

## Три испытания

1. [Системный аудит](system-audit/README.md)
2. [Осенняя окраска листьев](autumn-leaves/README.md)
3. [Погода в Амстердаме](amsterdam-weather/README.md)

## Архив transcript-файлов

В подпапках `hermes.md` и `claude-code.md` сохранены тексты, показанные в переписке. Где вывод был обрезан или повреждён форматированием, это явно отмечено. Они не заменяют raw screen recordings.

## Вывод

Hermes чаще выдавал более быстрый, аккуратно оформленный ответ. Claude Code показал более длинные последовательности инструментальных действий, включая неудачные Fetch-вызовы и восстановление через Open-Meteo. В обоих случаях базовая модель была одна и та же; различия демонстрируют агентские оболочки и инструменты, а не две разные базовые LLM.
