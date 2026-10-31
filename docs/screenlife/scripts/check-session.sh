#!/usr/bin/env bash
set -Eeuo pipefail

API_URL="http://127.0.0.1:8888/api/health"

echo "===== LLAMA-SERVER PROCESSES ====="
mapfile -t LLAMA_PIDS < <(pgrep -x llama-server || true)
printf 'Count: %s\n' "${#LLAMA_PIDS[@]}"

UNSLOTH_PORT=""
for pid in "${LLAMA_PIDS[@]}"; do
  [[ -r "/proc/$pid/cmdline" ]] || continue
  CMD="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
  printf '\nPID %s\n%s\n' "$pid" "$CMD"
  if [[ "$CMD" == *"/.unsloth/llama.cpp/llama-server"* ]]; then
    UNSLOTH_PORT="$(sed -nE 's/.*--port[[:space:]]+([0-9]+).*/\1/p' <<< "$CMD")"
  fi
done

echo
echo "===== UNSLOTH API :8888 ====="
API_OK=0
if curl -fsS --max-time 3 "$API_URL" >/dev/null 2>&1; then
  echo "HTTP 200"
  API_OK=1
else
  echo "NOT HEALTHY"
fi

echo
echo "===== MODEL SERVER HEALTH ====="
MODEL_OK=0
if [[ -n "$UNSLOTH_PORT" ]]; then
  echo "Detected internal model port: $UNSLOTH_PORT"
  if curl -fsS --max-time 3 "http://127.0.0.1:$UNSLOTH_PORT/health" >/dev/null 2>&1; then
    echo "HTTP 200"
    MODEL_OK=1
  else
    echo "NOT HEALTHY"
  fi
else
  echo "Unsloth llama-server port was not detected."
fi

echo
echo "===== LEGACY HERMES PORT :18434 ====="
if ss -ltn | grep -qE '127\.0\.0\.1:18434[[:space:]]'; then
  echo "LISTENING — legacy Hermes server is still present."
else
  echo "Not listening."
fi

if (("${#LLAMA_PIDS[@]}" != 1)) || [[ "$API_OK" != 1 ]] || [[ "$MODEL_OK" != 1 ]]; then
  echo
  echo "SESSION CHECK FAILED — review the lines above."
  exit 1
fi

echo
echo "SESSION CHECK PASSED — one Unsloth llama-server and both health checks are OK."
