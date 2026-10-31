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


## 7. Unsloth CLI — current 2026-10-31 runtime checkpoint

**Status:** VERIFIED for model load and direct OpenAI-compatible API generation.

Exact user-executed command:

```bash
unsloth run \
  --model "/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf" \
  --context-length 160000 \
  --gpu-memory-mode manual \
  --parallel 1 \
  --port 8888 \
  --host 127.0.0.1 \
  --disable-tools
```

Observed:
- Unsloth CLI `2026.10.11`.
- Client API: `http://127.0.0.1:8888/v1`.
- Internal llama-server port: `53815` in this run only; dynamic.
- Model loaded and server ready.
- `/v1/models` returned HTTP 200 and reported Qwen3.5-9B-Q4_K_M loaded, context 160000, native/max context 262144.
- A real Chat Completions request returned HTTP 200 and the expected response.

Do not substitute the internal port for the Unsloth API endpoint. Do not replace this launch with a direct `llama-server` command; Unsloth CLI is the required lifecycle manager for this setup.

Note: `--disable-tools` was present. Verify agent-side tool execution separately before claiming full agent functionality.

## 8. Hermes Custom provider — current configuration observed 2026-10-31

**Status:** OBSERVED; Gateway runtime test pending.

- Provider: `custom`.
- Base URL: `http://127.0.0.1:8888/v1`.
- Model: `Qwen3.5-9B-Q4_K_M`.
- API mode: `chat_completions`.
- Configured context: `160000`.
- Environment variable name: `HERMES_CUSTOM_127_0_0_1_8888_API_KEY`; confirmed present in `~/.hermes/.env`. Secret value is not documented.
- Fallback model configured: `Ministral-3-3B-Instruct-2512-Q4_K_M`; fallback behaviour has not been tested in this checkpoint.

The config is pointed at the correct Unsloth API. This alone does not prove the systemd Gateway has loaded the environment or can complete a request.

## 9. Legacy Hermes model service

Latest observed status: `llama-server.service = inactive`. Keep it inactive while Unsloth owns the single Qwen inference server. Do not start it as part of Hermes Gateway recovery.
