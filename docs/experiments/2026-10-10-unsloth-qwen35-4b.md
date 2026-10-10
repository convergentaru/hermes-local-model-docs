# Отчёт эксперимента: Unsloth + Qwen3.5-4B + Hermes

Дата: 2026-10-10. Статус: базовый текстовый маршрут успешно проверен.

## Цель

Проверить, что Unsloth Desktop использует общую библиотеку GGUF, нашу собственную CUDA-сборку llama.cpp и подключается к визуальному Hermes.

## Конфигурация

- GGUF: `/home/oleg/models/qwen35-4b/Qwen3.5-4B-Q4_K_M.gguf`.
- API alias: `qwen35-4b`.
- Путь к бинарнику: `/home/oleg/llama.cpp/build-cublas/bin/llama-server`.
- В Unsloth выбран GGUF Inference Engine = CUDA.
- Custom Llama CPP Folder = `/home/oleg/llama.cpp/build-cublas/bin`; интерфейс принял путь.
- Фактический порт во время проверки: `36679` (динамический).
- Командная строка включала `-c 238592`, `--parallel 4`, `--kv-unified`, `--fit off`, `-ngl -1`, Flash Attention, Jinja и reasoning.
- API `/v1/models` сообщил `n_ctx=238592` и `n_ctx_train=262144`.

Порт и аргументы могут измениться после нового старта. Не сохранять созданный локальный API key из `~/.unsloth/studio/auth/`.

## Результаты

- Unsloth Desktop получил короткое задание и вернул `UNSLOTH_CUDA_TEST_OK`.
- UI показал `68.4 tok/s`.
- `pgrep -af llama-server` подтвердил использование пользовательского бинарника.
- Запрос к API без авторизации вернул `Not authenticated`; API требует авторизацию.
- Выполнена команда `unsloth start hermes --app`. Затем визуальный Hermes вернул тестовую строку. Это подтверждает базовый текстовый обмен через Unsloth.

## Снимок ресурсов

При работающем сервере:
- RAM total: 11 GiB, available около 5.0 GiB.
- Swap total: 4.0 GiB, used около 1.7 GiB.
- VRAM: 11,425 MiB / 12,288 MiB.

Свободный запас VRAM невелик. Не запускать вторую тяжёлую модель на GPU одновременно.

## Что ещё не доказано

- Устойчивость длинной сессии при контексте 238592.
- Что каждый из четырёх параллельных слотов может независимо использовать огромный контекст.
- Голосовой маршрут от Hermes к Qwen3-ASR.
- TTS-озвучивание ответа.
- Сравнительная скорость custom runner против bundled runner на одинаковом бенчмарке.

## Повторная проверка

1. Запустить Qwen3.5-4B в Unsloth Desktop.
2. Отправить `Ответь ровно: UNSLOTH_CUDA_TEST_OK`.
3. Проверить `pgrep -af llama-server` без публикации секретных аргументов.
4. Для подключения модели к визуальному Hermes выполнить `unsloth start hermes --app`.
5. В Hermes отправить `Ответь ровно: HERMES_UNSLOTH_OK`.

## Вывод

Для практического использования сейчас приоритетен маршрут Unsloth Desktop → Qwen3.5-4B → визуальный Hermes. Следующий этап — завершить STT/TTS и проверить переключение моделей через GUI. Не возвращаться к запуску Qwen3.6-35B с 64K на текущей системе.
