---
name: local-ai-stack-diagnostics
description: Diagnose local model routing without unsafe config edits.
version: 0.1.0
author: Robot Factory OS maintainers, ChatGPT
platforms: [linux]
metadata:
  hermes:
    tags: [local-models, unsloth, llama-cpp, diagnostics]
    category: devops
---

# Local AI Stack Diagnostics Skill

Diagnose the local model route across Hermes Desktop, Unsloth Studio, and its managed llama.cpp worker. This skill prioritizes read-only checks and does not rewrite provider configuration based only on differing port numbers.

## When to Use

Use when Hermes reports a provider, endpoint, port, authentication, model-unavailable, or connection error for a local model.

Do not use this as a reason to reconfigure unrelated LiteLLM/llama-swap services or to increase context limits.

## Prerequisites

- Linux host with Hermes Desktop and Unsloth installed.
- User permission for read-only diagnostics.
- Never request or print API keys, passwords, or entire secret-bearing config files.

## How to Run

In Hermes, invoke `/local-ai-stack-diagnostics` and include the exact error message. Use the `terminal` tool for the read-only commands below.

## Quick Reference

~~~bash
ss -ltnp
pgrep -af llama-server
ps -ww -eo pid,args | grep '[l]lama-server'
free -h
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
~~~

These commands inspect processes and resources. Do not paste secret values from process arguments or key files into chat or GitHub.

## Procedure

1. **Classify the failure.** Ask whether the last known text test through the visual Hermes returned the exact expected response. If it did, treat the main text route as working unless there is a newer concrete failure.
2. **Inspect active listeners.** Run `ss -ltnp`. Record only relevant local listeners such as Unsloth Studio (often 8888), the managed llama-server worker (often a dynamically assigned port), and any separately configured LiteLLM/llama-swap ports.
3. **Inspect the worker.** Run `pgrep -af llama-server`. Identify the active model, alias, port and context arguments. Redact key values and never open/print the contents of API-key files.
4. **Explain the layers before changing anything.** In this installation, Unsloth Studio/API entry has been on port 8888, while its model worker has run on a separate dynamic port (observed examples included 36679 and 41879). This can be normal: Studio manages the backend worker and exposes its own authenticated API/provider route. Different ports alone do not prove misconfiguration.
5. **Check the established route.** If `unsloth start hermes --app` has already been run and Hermes returned `HERMES_UNSLOTH_OK`, the text route is proven. Do not switch Hermes to direct `llama-cpp` just because `llama-server` has another port.
6. **Interpret authentication errors correctly.** An unauthenticated request to Studio's `/v1/models` endpoint returned `Not authenticated` in this setup. That is evidence the endpoint requires authentication, not evidence the server is broken. Do not disable auth to make a test pass.
7. **If the route actually fails, test one layer at a time.** First confirm that the model responds in Unsloth Desktop. Then check the Hermes provider/model selection. Re-run `unsloth start hermes --app` only when needed—for example, after loading a different model in Unsloth. Finally, start a fresh Hermes session and send a short fixed response test.
8. **Inspect configuration safely.** If a config file must be inspected, parse only non-secret fields (provider, model name, base URL) and redact keys containing key, token, secret, password or credential. Never dump the full `~/.hermes/config.yaml` or Unsloth auth directory.
9. **Change config only with evidence and permission.** Before edits, make a timestamped backup. Change only the single proven incorrect field. Do not overwrite the full configuration and do not replace Unsloth with direct llama.cpp unless the user specifically chooses to bypass Studio.
10. **Report a crisp outcome.** State what is confirmed, what remains uncertain, which exact command was tested and the result. If a patch/tool action reports that it did not execute, do not claim the file was changed; verify state first.

## Pitfalls

- **False diagnosis: port mismatch.** A Studio/API port and a managed llama-server worker port may differ by design. Preserve the Unsloth provider route when it works.
- **False diagnosis: unauthenticated API fails.** A protected endpoint rejecting an anonymous request is expected.
- **Config patch stalled.** “Patch action was not executed” means there is no evidence of a change from that action; read back the sanitized fields before proceeding.
- **Context requirement.** Hermes currently documents a 64K minimum for standard agent workflows. Do not force Qwen3.6-35B to 64K on this machine: a previous attempt froze the computer. Check actual server context and memory before suggesting any increase.
- **Multiple stacks.** Do not change LiteLLM/llama-swap just because an Unsloth worker appears on a different port.

## Verification

A successful test requires a response from the selected model through the actual Hermes Desktop route (for example, `HERMES_UNSLOTH_OK`), not merely a running process or an open TCP port.
