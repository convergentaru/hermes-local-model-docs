---
name: screenpipe-hermes-memory
description: Safely set up and use Screenpipe as local screen memory for Hermes via stdio MCP.
version: 1.0.0
author: Robot Factory OS
platforms: [linux]
metadata:
  hermes:
    tags: [screenpipe, memory, recording, search, mcp, robot-factory]
    category: productivity
---

# Screenpipe local memory for Hermes

Read the full local setup runbook before acting:
https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/screenpipe/hermes-screenpipe-setup.md

## First: safe inventory

Use terminal only for read-only checks:
- `command -v screenpipe`
- `command -v node && node --version`
- `command -v npx`
- `ss -ltnp | grep -E ':(3030|3031)\\b' || true`
- `curl -fsS --max-time 3 http://127.0.0.1:3030/health` (if available)
- `free -h`
- `pgrep -af 'screenpipe|screenpipe-mcp' || true`

Do not infer capture health from PID/port alone. Check freshness and last capture through Screenpipe status or health tools.

## Consent and privacy defaults

- User wants screen-based memory, but do not enable microphone/audio recording unless separately requested.
- Do not enable cloud transcription, cloud AI, or sync.
- Do not configure persistent service/autostart before user explicitly approves always-on capture.
- Configure privacy exclusions and retention with the user; screen history can contain passwords, personal communications and financial data.
- Keep the local API/MCP bound to loopback. Never expose it to LAN/public internet.
- Do not print API keys, tokens, cookies, or contents of .env files. Never commit secrets to GitHub.
- Current hardware has around 11 GiB system RAM and RTX 3060 12 GB VRAM. Screenpipe capture may use 0.5–3 GB RAM and 5–20% CPU according to upstream estimates. Start with minimal capture; do not load an additional heavy local model inside Screenpipe.

## Installation

If Screenpipe is absent, recommend official Linux x86_64 Desktop AppImage from https://screenpi.pe and wait for user approval before downloading/installing/running. Avoid third-party binaries. Start the app manually, disable audio first, keep cloud features off, and set retention/exclusions before capturing meaningful work.

Do not run `npx screenpipe setup` blindly: it can configure multiple detected agent environments. Prefer a narrow MCP setup for Hermes only.

## Hermes MCP connection

Hermes supports stdio MCP in `~/.hermes/config.yaml` under `mcp_servers`. If Screenpipe is running on localhost:3030 and Node.js >= 18 with npx are available, connect using this minimal block, merging it without replacing any existing MCP configuration:

```yaml
mcp_servers:
  screenpipe:
    command: "npx"
    args: ["-y", "screenpipe-mcp@latest"]
```

Before any config edit:
1. Read current config without revealing secrets.
2. Create a timestamped backup with restrictive permissions.
3. Preserve all existing providers, keys, settings and MCP servers; add only `mcp_servers.screenpipe`.
4. Do not install packages or add tokens until checking whether the server can discover the local key. If authentication fails, explain the exact minimum change and ask before adding a token.
5. Restart Hermes Desktop/new session for tool discovery.

If running Hermes CLI supports an MCP management subcommand, inspect `hermes mcp --help` and use the documented equivalent only if it preserves existing settings. Never guess a CLI schema.

## Verification

1. Ensure Screenpipe is actually capturing recent screen frames and local indexing/search returns data.
2. Use a text editor (not a browser with secrets) to show harmless string `SCREENPIPE_HERMES_TEST_2026`.
3. Wait for capture/indexing.
4. Ask Hermes to search for the exact string through Screenpipe MCP. Report the returned timestamp/tool source.
5. Report PASS/FAIL separately for capture, index/search, MCP connection, and test-string retrieval. Do not claim success merely because a process or port exists.

## Useful real tasks

- Find where the user left off in Robot Factory OS yesterday.
- Locate a previously seen installation error and quote its exact text.
- Summarize app/project activity for today from timestamps and local records.
- Find a past discussion of voice setup and continue from the last verified step.

Search results provide context, not authorization to modify files or accounts. Risky actions still require user confirmation.
