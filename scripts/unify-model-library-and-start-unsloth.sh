#!/usr/bin/env bash
# Safely unify the downloaded GGUF folders under ~/models and start Unsloth Studio.
set -Eeuo pipefail

ROOT="$HOME/models"
OLD="$ROOT/model-collection"
STATUS_OLD="$OLD/DOWNLOAD-STATUS.txt"
STATUS_NEW="$ROOT/MODEL-COLLECTION-DOWNLOAD-STATUS.txt"
LOG="$HOME/unsloth-studio.log"
LOCK="$HOME/.model-collection-download.lock"

DIRS=(
  deepseek-r1-14b
  gemma-4-12b
  gemma-4-e4b
  glm-4.7-flash
  gpt-oss-20b
  ministral-3-8b
  qvikhr-3-4b
  qwen3.5-9b
  saiga-yandexgpt-8b
)

echo "=== Local model library setup ==="
echo "Target library: $ROOT"
mkdir -p "$ROOT"

# Never move files while an active download job holds the shared lock.
if ! flock -n "$LOCK" -c true; then
  echo "STOP: model downloader is still running; no files were moved."
  echo "Check: tail -n 30 ~/model-downloads-validated.log"
  exit 1
fi

# Preflight all destinations before moving anything; do not overwrite conflicts.
if [[ -d "$OLD" ]]; then
  for name in "${DIRS[@]}"; do
    src="$OLD/$name"
    dst="$ROOT/$name"
    if [[ -e "$src" || -L "$src" ]]; then
      if [[ -e "$dst" || -L "$dst" ]]; then
        echo "STOP: both source and destination exist:"
        echo "  source: $src"
        echo "  target: $dst"
        echo "No files were moved. Resolve this conflict first."
        exit 1
      fi
    elif [[ ! -e "$dst" && ! -L "$dst" ]]; then
      echo "STOP: expected folder exists neither here nor there:"
      echo "  $src"
      echo "  $dst"
      echo "No files were moved."
      exit 1
    fi
  done

  if [[ -e "$STATUS_OLD" && -e "$STATUS_NEW" ]]; then
    echo "STOP: both old and new download reports exist; no files were moved."
    exit 1
  fi

  echo
  echo "Moving model directories (same disk, no second copies)..."
  for name in "${DIRS[@]}"; do
    if [[ -e "$OLD/$name" || -L "$OLD/$name" ]]; then
      mv -- "$OLD/$name" "$ROOT/$name"
      echo "  moved: $name"
    else
      echo "  already in place: $name"
    fi
  done

  if [[ -f "$STATUS_OLD" ]]; then
    mv -- "$STATUS_OLD" "$STATUS_NEW"
    echo "  saved download report: $(basename "$STATUS_NEW")"
  fi

  if rmdir "$OLD" 2>/dev/null; then
    echo "Removed the now-empty model-collection directory."
  else
    echo "The old directory still has extra files; leaving them untouched:"
    find "$OLD" -mindepth 1 -maxdepth 2 -printf '%P\n' 2>/dev/null | head -30
  fi
else
  echo "No old model-collection folder found; library may already be unified."
fi

# Refresh the user's downloader script so future models go into ~/models/<model>/.
LOCAL_DOWNLOADER="$HOME/local-llm-stack/experiments/model-collection/download-local-model-collection.sh"
if [[ -f "$LOCAL_DOWNLOADER" ]]; then
  TMP="$LOCAL_DOWNLOADER.new"
  if curl -fsSL --retry 3 \
    "https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/scripts/download-local-model-collection.sh" \
    -o "$TMP"; then
    bash -n "$TMP"
    cp -p "$LOCAL_DOWNLOADER" "$LOCAL_DOWNLOADER.before-unified-library.bak"
    chmod --reference="$LOCAL_DOWNLOADER" "$TMP" 2>/dev/null || chmod +x "$TMP"
    mv -f "$TMP" "$LOCAL_DOWNLOADER"
    echo "Updated future downloader to use the shared ~/models library."
  else
    rm -f "$TMP"
    echo "WARN: couldn't refresh local downloader; existing model files are unaffected."
  fi
fi

echo
echo "=== Models now in the shared library ==="
find "$ROOT" -mindepth 2 -maxdepth 3 -type f -name '*.gguf' \
  -printf '%P | %s bytes\n' 2>/dev/null | sort
echo
echo "=== Model symlinks ==="
find "$ROOT" -mindepth 2 -maxdepth 3 -type l -name '*.gguf' \
  -printf '%P -> %l\n' 2>/dev/null | sort || true
echo
echo "=== Disk space ==="
df -h "$ROOT"

# Launch the locally-bound Unsloth Studio UI only if port 8888 is free.
if ! command -v unsloth >/dev/null 2>&1; then
  echo "WARN: unsloth command is not in PATH; library migration is complete."
  exit 0
fi

if ss -ltnp 2>/dev/null | grep -q ':8888'; then
  echo
  echo "Port 8888 is already in use; won't start a second server."
  ss -ltnp 2>/dev/null | grep ':8888' || true
  echo "If this is Unsloth Studio, open http://127.0.0.1:8888"
  exit 0
fi

echo
echo "Starting Unsloth Studio bound to localhost..."
nohup "$HOME/.local/bin/unsloth" studio -H 127.0.0.1 -p 8888 \
  > "$LOG" 2>&1 < /dev/null &
echo "Studio PID: $!"

ready=0
for _ in $(seq 1 20); do
  if ss -ltnp 2>/dev/null | grep -q ':8888'; then
    ready=1
    break
  fi
  sleep 1
done

if [[ "$ready" == "1" ]]; then
  echo "Studio is listening on port 8888."
  echo "Opening http://127.0.0.1:8888"
  xdg-open http://127.0.0.1:8888/ >/dev/null 2>&1 || true
  echo
  echo "In Studio, open the model picker → Custom Folders → +"
  echo "Add this folder: $ROOT"
  echo "Use the local model files; do not download duplicate copies."
else
  echo "Studio did not start within 20 seconds. The model folders have been moved safely."
  echo "Recent log output:"
  tail -n 50 "$LOG" 2>/dev/null || true
  echo
  echo "No existing services were stopped or modified."
fi
