#!/usr/bin/env bash
set -euo pipefail

REPO="convergentaru/hermes-local-model-docs"
SKILLS=(
  "robot-factory-setup"
  "local-ai-stack-diagnostics"
  "unsloth-hermes-connect"
  "hermes-voice-setup"
)

if ! command -v hermes >/dev/null 2>&1; then
  echo "ERROR: Hermes CLI was not found. Install Hermes first, then rerun this script." >&2
  exit 1
fi

echo "Hermes version:"
hermes --version
echo

if ! hermes skills tap list 2>/dev/null | grep -Fq "$REPO"; then
  echo "Adding GitHub skills source: $REPO"
  hermes skills tap add "$REPO"
else
  echo "GitHub skills source is already configured: $REPO"
fi

for name in "${SKILLS[@]}"; do
  if hermes skills list 2>/dev/null | grep -Fq "$name"; then
    echo "SKIP: $name already appears in the local skill list."
  else
    echo
    echo "Installing from GitHub: $REPO/$name"
    hermes skills install "$REPO/$name"
  fi
done

echo
echo "Installed/available Robot Factory skills:"
hermes skills list | grep -E 'robot-factory-setup|local-ai-stack-diagnostics|unsloth-hermes-connect|hermes-voice-setup' || true

echo
echo "Done. Start a new Hermes session (or use /reset if supported)."
echo "Main entry point: /robot-factory-setup"
