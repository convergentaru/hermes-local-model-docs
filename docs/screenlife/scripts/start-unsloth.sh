#!/usr/bin/env bash
set -Eeuo pipefail

MODEL="/home/oleg/.hermes/models/Qwen3.5-9B-Q4_K_M.gguf"
API_HOST="127.0.0.1"
API_PORT="8888"
API_HEALTH="http://${API_HOST}:${API_PORT}/api/health"

if ! command -v unsloth >/dev/null 2>&1; then
  echo "ERROR: unsloth CLI not found in PATH." >&2
  exit 1
fi

if [[ ! -r "$MODEL" ]]; then
  echo "ERROR: model file is not readable: $MODEL" >&2
  exit 1
fi

if curl -fsS --max-time 2 "$API_HEALTH" >/dev/null 2>&1; then
  echo "Unsloth API is already healthy at http://${API_HOST}:${API_PORT}."
  echo "Refusing to start another instance."
  exit 0
fi

mapfile -t RUNNING_LLAMA_PIDS < <(pgrep -x llama-server || true)
if (("${#RUNNING_LLAMA_PIDS[@]}" > 0)); then
  echo "ERROR: llama-server process(es) already exist, but Unsloth API is not healthy." >&2
  printf 'PID %s\n' "${RUNNING_LLAMA_PIDS[@]}" >&2
  echo "Inspect the existing process before starting anything else." >&2
  exit 1
fi

exec unsloth run \
  --model "$MODEL" \
  --context-length 160000 \
  --parallel 1 \
  --gpu-memory-mode manual \
  --api-only \
  --host "$API_HOST" \
  --port "$API_PORT"
