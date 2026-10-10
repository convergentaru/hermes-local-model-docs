---
name: hermes-voice-setup
description: Configure and verify Hermes speech input and output.
version: 0.1.0
author: Robot Factory OS maintainers, ChatGPT
platforms: [linux]
metadata:
  hermes:
    tags: [hermes, voice, speech-to-text, text-to-speech, unsloth]
    category: productivity
---

# Hermes Voice Setup Skill

Configure voice input and spoken responses in the existing visual Hermes app. Separate speech recognition (STT), the language model (LLM), and speech synthesis (TTS); one working component does not prove the others are connected.

## When to Use

Use when the user wants to dictate tasks to Hermes, use local speech recognition, or hear Hermes responses aloud.

Do not claim Qwen3-ASR is integrated with Hermes unless an actual Hermes-to-ASR API request has been verified.

## Prerequisites

- Visual Hermes Desktop is working for text.
- Unsloth Desktop is available if testing Qwen3-ASR-0.6B.
- User can access the Hermes Voice settings.
- Do not send user audio to a remote provider without explaining that this is not fully local and getting the user's choice.

## How to Run

Invoke `/hermes-voice-setup`. Use `terminal` only for read-only checks or a specifically requested API test. UI changes require user action; give one step at a time and use screenshots when available.

## Procedure

1. **Keep the known-good text route.** Do not change the main Hermes model/provider while setting up voice.
2. **Choose Chained for the first local-oriented test.** In Hermes Desktop, open voice settings and choose `Chained` if available. Avoid `GPT Live`/duplex until its provider and external-service requirements are understood.
3. **Enable STT.** Keep Speech-to-Text enabled and transcription confirmation enabled during initial tests. Set transcription language to Russian if the option exists.
4. **Understand Hermes's local STT options.** The observed UI offered Whisper `base`, `small`, `medium` and `large-v3`. Selecting these tests the STT path built into Hermes; it does not automatically use Qwen3-ASR in Unsloth.
5. **Treat Qwen3-ASR as a separate integration.** The user tested Qwen3-ASR-0.6B in Unsloth and it transcribed Russian well. Before configuring Hermes to use it, verify that this Unsloth version exposes a compatible transcription endpoint, that the endpoint supports authentication, and that the Hermes UI/config can call it. Do not assume compatibility based solely on success inside Unsloth.
6. **Test one short utterance.** Ask the user to record a short Russian sentence. Confirm the transcript is accurate before proceeding.
7. **Configure TTS independently.** Open Text-to-Speech settings, choose a provider/voice that is actually available, and test a short Russian response. If the available option is cloud-based, explain that spoken text may leave the local machine; do not select it silently.
8. **Test the complete chain.** User speaks → visible transcript appears → Hermes answers through the selected local LLM → TTS plays the answer. If any stage fails, identify which stage first failed; do not reset all settings.
9. **Record the actual selections.** Document provider, language, model, execution mode (RAM/CPU or GPU), and test result. Never record keys or tokens.

## Resource Guidance

RTX 3060 has 12 GB VRAM and the system has around 11 GiB RAM. When Qwen3.5-4B was running through Unsloth, a snapshot showed 11,425 MiB used VRAM. Do not load another audio/LLM model on GPU simultaneously without rechecking memory. RAM/CPU may save VRAM but may be slower and still use system memory; measure before deciding.

## Pitfalls

- STT does not perform TTS.
- Chained mode does not guarantee all components are local.
- A model visible in Unsloth's Voice area is not automatically a Hermes STT provider.
- Do not change the primary model while debugging speech.
- If voice hotkeys are active in multiple desktop apps, check for a microphone/shortcut conflict.

## Verification

Record three separate outcomes:
1. STT correctly transcribes a short Russian utterance.
2. Hermes gives a text response to that utterance via the selected local model.
3. A TTS provider actually speaks the response.

Report each as PASS/FAIL/NOT TESTED. Never claim full voice integration after checking only STT inside Unsloth.


## First live conversation checklist

Follow the maintained checklist before declaring voice ready:
https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/voice/hermes-desktop-first-voice-test.md

Launch Desktop in the project folder with `hermes desktop --cwd "$HOME/robot-factory-os"` when it is not already open. Verify the exact active Unsloth model and text response first. Then configure Chained, local Whisper STT, Russian language and transcript confirmation. Test TTS separately and disclose any cloud provider before enabling it. Keep the currently working provider and API key unchanged.
