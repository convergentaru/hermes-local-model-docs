#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/convergentaru/hermes-local-model-docs/main/skills"

if ! command -v hermes >/dev/null 2>&1; then
  echo "ERROR: command 'hermes' not found. Install Hermes Agent first." >&2
  exit 1
fi

install_skill() {
  local name="$1"
  local url="$2"

  if hermes skills list 2>/dev/null | grep -Fq "$name"; then
    printf 'SKIP: %s already appears in hermes skills list. Existing version was not overwritten.\n' "$name"
  else
    printf '\nInstalling %s...\n' "$name"
    hermes skills install "$url" --name "$name"
  fi
}

install_skill "local-ai-stack-diagnostics" "$BASE_URL/local-ai-stack-diagnostics/SKILL.md"
install_skill "unsloth-hermes-connect" "$BASE_URL/unsloth-hermes-connect/SKILL.md"
install_skill "hermes-voice-setup" "$BASE_URL/hermes-voice-setup/SKILL.md"

printf '\nInstalled/available skills:\n'
hermes skills list | grep -E 'local-ai-stack-diagnostics|unsloth-hermes-connect|hermes-voice-setup' || true
printf '\nStart a new Hermes session (or /reset) so the skill list is refreshed.\n'
