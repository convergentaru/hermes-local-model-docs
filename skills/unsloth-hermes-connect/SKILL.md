---
name: unsloth-hermes-connect
description: Connect Hermes Desktop to the model managed by Unsloth.
version: 0.1.0
author: Robot Factory OS maintainers, ChatGPT
platforms: [linux]
metadata:
  hermes:
    tags: [hermes, unsloth, local-models, api]
    category: devops
---

# Unsloth to Hermes Desktop Skill

Connect the already-running Unsloth model to the existing visual Hermes Desktop app. Preserve the Unsloth-managed API route; do not replace it with a direct llama.cpp endpoint merely because the underlying worker uses a different port.

## When to Use

Use after launching or switching a model in Unsloth Desktop, or when the existing visual Hermes app no longer sees the Unsloth provider/model.

Do not use to change the legacy LiteLLM/llama-swap stack unless the user explicitly requests that.

## Prerequisites

- Unsloth Desktop is installed and its chosen model is loaded.
- The user wants to keep using the visual Hermes application.
- Do not request, print, commit, or paste the generated Unsloth API key.

## How to Run

Invoke `/unsloth-hermes-connect`. If a model is not running yet, ask the user to select and load it in Unsloth Desktop first. Use the `terminal` tool for the connection command.

## Procedure

1. **Confirm the selected model in Unsloth Desktop.** Prefer a model already tested in the GUI. Do not start a second model on the GPU while VRAM is nearly full.
2. **Confirm basic inference in Unsloth.** Send a short prompt like `Ответь ровно: UNSLOTH_MODEL_OK`. Continue only if the model responds.
3. **Connect the desktop app.** Run:
   
   ~~~bash
   unsloth start hermes --app
   ~~~
   
   This is the supported command in the installed version. Its help describes it as adding the Unsloth provider and its API key to the desktop app configuration after backing up the app config, while leaving the default model alone so the user can pick Unsloth in the model picker.
4. **Select provider in the visual Hermes.** Open Hermes Desktop, go to its model/provider picker, and select the Unsloth provider/model. Do not assume the CLI command automatically switches the selected model in the GUI.
5. **Run a text smoke test.** Send `Ответь ровно: HERMES_UNSLOTH_OK`. Confirm the response comes from the intended local model.
6. **After model switching.** If the user loads a different model in Unsloth, re-run `unsloth start hermes --app` as the installed CLI help instructs; select the correct provider/model in the app and repeat the smoke test.
7. **If a request fails.** Use `/local-ai-stack-diagnostics` if installed, or inspect active listeners and model alias first. Do not patch `~/.hermes/config.yaml` based only on the model worker port.

## Pitfalls

- Unsloth Studio/API entry and its managed llama-server worker can use separate ports. In this setup 8888 was the Studio/API entry and 36679/41879 examples were backend workers. Treat these as observations, not fixed ports.
- The Studio API may reject unauthenticated requests. Use the auth/provider setup produced by Unsloth rather than disabling auth.
- A successful terminal/GUI model test does not prove voice input or TTS works; those have separate routes and are handled by the voice skill.
- Do not set a context value higher than the actual context served by the model.
- Do not change to direct llama.cpp if the Unsloth provider route already passes the smoke test.

## Verification

The skill is complete only when:
- the intended model responds in Unsloth Desktop;
- Unsloth is selectable in visual Hermes;
- Hermes returns `HERMES_UNSLOTH_OK` in a new chat/session;
- no secrets have been exposed and no unrelated service config has been changed.
