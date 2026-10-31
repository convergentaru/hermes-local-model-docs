#!/usr/bin/env bash
set -Eeuo pipefail

API_HEALTH="http://127.0.0.1:8888/api/health"

if ! command -v unsloth >/dev/null 2>&1; then
  echo "ERROR: unsloth CLI not found in PATH." >&2
  exit 1
fi

if ! curl -fsS --max-time 3 "$API_HEALTH" >/dev/null 2>&1; then
  echo "ERROR: Unsloth API is not healthy at 127.0.0.1:8888." >&2
  echo "Start the Unsloth server first in Terminal 1." >&2
  exit 1
fi

mapfile -t LLAMA_PIDS < <(pgrep -x llama-server || true)
if (("${#LLAMA_PIDS[@]}" != 1)); then
  echo "ERROR: expected exactly one llama-server; found ${#LLAMA_PIDS[@]}." >&2
  printf 'PID %s\n' "${LLAMA_PIDS[@]}" >&2
  exit 1
fi

PROJECT_DIR="${1:-$PWD}"
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: project directory does not exist: $PROJECT_DIR" >&2
  exit 1
fi

cd "$PROJECT_DIR"
exec unsloth start claude --no-serve
