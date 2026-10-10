---
name: robot-factory-setup
description: Safely initialize and verify the local Hermes, Unsloth and voice workflow.
version: 1.0.0
author: Robot Factory OS
platforms: [linux]
metadata:
  hermes:
    tags: [robot-factory, local-ai, hermes, unsloth, voice, setup]
    category: devops
---

# Robot Factory OS: local AI setup

Use this as the single starting point for setting up or diagnosing this workstation after Hermes is installed. It orchestrates the other local skills and preserves working configuration.

## Important operating rules

- Diagnose first. Never overwrite the whole Hermes config just because ports differ.
- Never print, request, commit or send API keys, password files, or tokens.
- Never use sudo, install packages, kill processes, switch providers, or edit configuration without first stating the exact intended change and getting the user's confirmation.
- Before any config edit, create a timestamped backup and change only the proven incorrect field.
- Never set a model context larger than its real server context.
- Do not start Qwen3.6-35B with 64K context on this workstation: a previous attempt froze the computer.
- Do not load a second heavy model onto GPU without checking available VRAM.
- The UI may require the user to select a model, voice or microphone permission. State those steps explicitly; do not claim to have clicked the UI.

## Workstation facts

- Ubuntu computer, NVIDIA RTX 3060 12 GB VRAM, approximately 11 GiB RAM, 4 GiB swap.
- Models: `/home/oleg/models`.
- Unsloth Desktop uses GGUF inference engine CUDA.
- User-provided llama.cpp binary folder accepted by the GUI: `/home/oleg/llama.cpp/build-cublas/bin`.
- Known model tested in Unsloth: `/home/oleg/models/qwen35-4b/Qwen3.5-4B-Q4_K_M.gguf`.
- Unsloth managed llama-server may use a dynamic worker port. Studio/API entry port and worker port are different layers; the difference alone is not an error.
- A text test through visual Hermes and Unsloth previously passed. The exact current running state must still be checked.

## Runbook

### 1. Read-only inventory

Use the terminal tool for these safe checks:
- `command -v hermes`
- `hermes --version`
- `hermes skills list`
- `command -v unsloth`
- `ss -ltnp`
- `pgrep -af llama-server`
- `free -h`
- `nvidia-smi --query-gpu=memory.used,memory.total --format=csv`

When reporting, show only model names, relevant ports, context and resource totals. Redact any credentials or sensitive arguments.

### 2. Connect Unsloth to the visual Hermes

If the user has loaded the intended model in Unsloth and a short prompt works there:
1. Run `unsloth start hermes --app`.
2. Have the user select the Unsloth provider/model in visual Hermes.
3. Start a new session and test with `Ответь ровно: HERMES_UNSLOTH_OK`.
4. If it passes, keep the provider route. If a model is switched in Unsloth, rerun `unsloth start hermes --app` and select/check the model again.

Do not change Hermes to direct llama-cpp just because the worker is on a dynamic port such as 36679 or 41879 while Studio has used 8888. First verify actual request failure. An unauthenticated Studio API response saying `Not authenticated` is expected for a protected endpoint.

Use `/unsloth-hermes-connect` for the detailed procedure.

### 3. Configure voice as independent components

Goal: speech input -> Hermes/LLM -> spoken response.

1. Keep the text route working before changing voice.
2. In Hermes Desktop, start with Voice Chat Mode `Chained` if available.
3. Enable STT and confirmation of the transcript; choose Russian as transcription language if available.
4. Local Whisper choices seen in this UI were base/small/medium/large-v3. Testing Whisper in Hermes is distinct from using Qwen3-ASR inside Unsloth.
5. Qwen3-ASR-0.6B was tested in Unsloth and recognized Russian speech well. Direct routing from Hermes to this ASR is not yet proven; verify the API contract and authentication before claiming integration.
6. Set up TTS separately; STT does not read answers aloud. Check whether the chosen TTS provider is local or remote before selecting it.
7. Test one short phrase and one short spoken response independently.

Use `/hermes-voice-setup` for the detailed procedure.

### 4. Diagnose routing and memory errors

Use `/local-ai-stack-diagnostics`. Treat a message from an agent that says a patch stalled or did not execute as proof that the patch was NOT applied. Read back the sanitized current config before trying another change.

### 5. Finish with a status report

Report a checklist with PASS / FAIL / NOT TESTED:
- model answers in Unsloth Desktop;
- visual Hermes talks to Unsloth;
- speech is transcribed in Hermes;
- Hermes answers the transcription;
- TTS speaks the response.

Do not claim end-to-end voice is ready until all three voice stages (STT, LLM answer, TTS) are tested.

## Links

- [Local stack architecture](https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/architecture/current-local-ai-stack.md)
- [Hermes Desktop checklist](https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/hermes/desktop-practical-checklist.md)
- [Unsloth and custom llama.cpp](https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/unsloth/studio-model-library-and-custom-llama-cpp.md)
- [Voice setup](https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/voice/qwen3-asr-and-hermes-voice.md)
- [Aider and Little-coder](https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/coding-agents/aider-and-little-coder.md)
