# KNOWN_GOOD_CONFIGS — проверенные конфигурации

Последнее обновление: 2026-10-31

В этом файле намеренно разделены подтверждённые конфигурации и исторические параметры. Наличие записи не означает, что компонент работает в текущем сеансе.

## 1. Unsloth Desktop — исторически проверенная база

Источник: [документация от 2026-10-10](docs/unsloth/studio-model-library-and-custom-llama-cpp.md).

- Model library: `/home/oleg/models`.
- GPU backend: CUDA.
- Custom Llama CPP Folder: `/home/oleg/llama.cpp/build-cublas/bin`.
- Проверялось наличие исполняемого `llama-server` и CUDA-библиотек.
- В тесте Qwen3.5-4B был получен ответ `UNSLOTH_CUDA_TEST_OK`; UI показывал 68.4 tok/s.

Статус: VERIFIED для того исторического теста Qwen3.5-4B. Не является доказательством работы Qwen3.5-9B сегодня.

## 2. Unsloth → Hermes Desktop — исторически проверенный маршрут

Команда из прежней документации:

```bash
unsloth start hermes --app
```

После загрузки модели команда добавляла провайдера Unsloth в конфигурацию Hermes Desktop. Визуальный Hermes затем вернул контрольную строку.

Статус: VERIFIED для исторического текстового теста. Не запускать Hermes параллельно с отдельной копией той же GGUF-модели.

## 3. Qwen3.5-9B — исторический профиль Unsloth

Модель:
`/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf`

Параметры, наблюдавшиеся в прежнем профиле:
- Context / max sequence length: 65 536;
- Parallel: 4;
- Flash Attention: On;
- Context Shift: Off;
- KV Unified: On;
- Fit: On;
- Context Checkpoints: 5;
- Reasoning: Off;
- Load Mode: mmap+mlock.

Статус: OBSERVED. Перед использованием восстановить фактический профиль через GUI; не полагаться только на этот список.

## 4. Claude Code — исторический профиль подключения

- Base URL: `http://127.0.0.1:8888`.
- Model alias: `Qwen3.5-9B-Q4_K_M`.
- Context setting: 65 536.
- Auto-compact override: 90%.
- Max output tokens: 16 384.

Статус: OBSERVED. Подключение ранее работало, но конкретная команда запуска должна быть восстановлена из настроек/документации установленной версии.

## 5. Не использовать как проверенный запуск

Следующая команда завершилась ошибкой CLI о необходимости prompt/stdin при использовании `--print`:

```bash
unsloth start claude --model /home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf --max-seq-length 65536
```

Статус: FAILED на 2026-10-31. Не повторять без выяснения правильного интерфейса CLI.

## 6. Обязательные ограничения

- Не запускать одну и ту же Qwen GGUF одновременно через Hermes llama-server и Unsloth worker.
- Не предполагать, что порт worker постоянный.
- Не печатать API keys, токены и секретные конфиги.
- Не менять параметры контекста, parallel или offload без оценки RAM/VRAM.
- Перед правкой профиля сохранить резервную копию или зафиксировать исходные значения.
