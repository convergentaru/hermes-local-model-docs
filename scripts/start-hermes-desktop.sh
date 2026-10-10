#!/usr/bin/env bash
set -euo pipefail

# Open Hermes Desktop in the Robot Factory OS project directory.
# This script does not edit configuration, install packages, or change models.

PROJECT_DIR="${HOME}/robot-factory-os"

if ! command -v hermes >/dev/null 2>&1; then
  echo "ERROR: Hermes CLI not found in PATH." >&2
  echo "Open the terminal normally used for Hermes and check its installation." >&2
  exit 127
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Project directory not found: $PROJECT_DIR" >&2
  echo "No directory was created; this script makes no filesystem changes." >&2
  exit 1
fi

echo "Starting Hermes Desktop in: $PROJECT_DIR"
echo "No configuration or model settings will be changed."
exec hermes desktop --cwd "$PROJECT_DIR"
