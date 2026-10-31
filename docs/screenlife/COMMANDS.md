# Команды и параметры

Все команды отражают настройку 31.10.2026. Секретные значения не сохраняются.

## Запуск Unsloth

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

Фактический лог подтвердил metadata context length 262144, выбранный context 160000, `--parallel 1`, llama-server аргумент `-c 160000`, загрузку модели и готовность сервера. Внутренний порт на той сессии — 55831, динамический.

## Claude Code

```bash
unsloth start claude --no-serve
```

`/status` подтвердил Claude Code 2.1.286, Anthropic base URL `http://127.0.0.1:8888` и модель Qwen3.5-9B-Q4_K_M.

## Первичная настройка Hermes Custom endpoint

```bash
hermes model
```

Выбранные параметры:
- Base URL: `http://127.0.0.1:8888/v1`
- API compatibility: Chat Completions
- Model ID: `Qwen3.5-9B-Q4_K_M`
- Context: 160000
- Display name: `Unsloth Qwen 160K`
- Reasoning: Disable reasoning

Мастер подтвердил обнаружение моделей через `/v1/models` и сохранение default model через Custom endpoint.

В сессии Hermes:
- `/model custom` сначала выбрал буквальную модель `custom` и выдал предупреждение;
- `/model custom:Qwen3.5-9B-Q4_K_M` выбрал точный ID;
- `/new --yes` создал новую сессию, которая ответила.

## Отключение отдельного runtime Hermes

```bash
hermes config set local_runtime.enabled false
hermes gateway restart --detach
```

После этого проверка показала один Unsloth llama-server и успешный ответ Gateway.

## Проверка процессов и портов

```bash
pgrep -af '[l]lama-server' || true
ss -ltnp | grep -E ':(18434|55831|8888)\\b' || true
```

В автоматизированных сценариях не фиксировать 55831: использовать фактический порт из argv процесса.

## Проверка API

```bash
curl -sS -o /dev/null -w "Unsloth API: HTTP %{http_code}\\n" \
  http://127.0.0.1:8888/api/health
```

Проверка внутреннего сервера на обнаруженном порту:

```bash
curl -sS -o /dev/null -w "llama-server: HTTP %{http_code}\\n" \
  "http://127.0.0.1:$MODEL_PORT/health"
```

## Реальный запрос к API

Выполнен скрытый ввод runtime ключа (значение в Git не сохранено):

```bash
read -rsp "Unsloth API key: " UKEY; echo
curl -sS --max-time 120 \
  -w '\\nHTTP %{http_code} | First byte: %{time_starttransfer}s | Total: %{time_total}s\\n' \
  http://127.0.0.1:8888/v1/chat/completions \
  -H "Authorization: Bearer $UKEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen3.5-9B-Q4_K_M","messages":[{"role":"user","content":"Ответь одним словом: ГОТОВО"}],"max_tokens":32,"temperature":0,"stream":false}'
unset UKEY
```

Результат: HTTP 200, ответ `ГОТОВО`, 4 completion tokens, first byte 3.413271 s, total 3.413405 s.

## История автоперезапуска

Остановка старого Hermes server командой `kill -TERM 248167` привела к автоматическому запуску нового процесса на :18434. Затем отключили `local_runtime.enabled`, перезапустили Gateway и добились одного сервера. Не использовать `kill` как повторяемый способ отключения runtime.
