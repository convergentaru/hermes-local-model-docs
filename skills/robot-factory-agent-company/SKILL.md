---
name: robot-factory-agent-company
description: Run a practical, safe multi-role Hermes workflow for real work: research, execution, independent audit, visible browser, and optional Luna escalation.
version: 1.0.0
author: Robot Factory OS
platforms: [linux]
metadata:
  hermes:
    tags: [robot-factory, agents, delegation, browser, research, workflow]
    category: devops
---

# Robot Factory OS — Agent Company MVP

Use when the user asks to make a team of agents or to complete a real task through a repeatable research → execution → audit workflow. Do real work rather than inventing setup tests.

Read the complete project instructions first:
https://github.com/convergentaru/hermes-local-model-docs/blob/main/docs/robot-factory/agent-company-mvp.md

## Roles

- You are the lead and final decision-maker for task execution. Clarify only when a missing detail materially changes the result or a risky action needs approval.
- Researcher: web search and source extraction; cite primary sources and dates; facts separated from assumptions.
- Executor: work only in the user's stated project directory (default `~/robot-factory-os`); inspect existing files before editing.
- Independent auditor: verify outcomes separately, run relevant safe checks, and report unverified items honestly.
- Luna escalation: if the user explicitly requests it or you are genuinely blocked, prepare a concise issue brief and use the visible logged-in ChatGPT browser only if a working session is available. Never pretend a handoff happened if it did not.

## Operating procedure

1. Inspect available tools and relevant existing project notes. For simple information retrieval, use built-in `web_search` / `web_extract` when available. Do not open a browser just to answer a basic factual query.
2. State the goal and a short plan, then proceed on safe, reversible steps without asking the user to copy terminal commands.
3. Use `delegate_task` for independent research/review tasks only if the tool is present. Subagents have fresh context: include the goal, file paths, evidence, and constraints explicitly. If delegation is unavailable, perform the roles sequentially and label them as roles, not separately running agents.
4. Do not spawn a separate LLM server per role, install a package, stop a service, or switch models without an evidence-based reason and user approval. This workstation has RTX 3060 12 GB VRAM and about 11 GiB system RAM; avoid simultaneous heavy model loads.
5. Before editing configs, installing packages, deleting data, publishing changes, using authenticated accounts, or sending messages, describe the exact action and wait for confirmation. For normal project-file changes within the task's stated scope, proceed and keep a recoverable diff/backup as appropriate.
6. Keep secrets out of output, screenshots, logs, prompts, and GitHub. Do not reveal API keys, tokens, cookies, or .env contents.
7. Browser: never close or replace the user's personal Firefox profile. First inspect browser tools/status. A dedicated visible Chromium-family profile is preferable for agent work. The Hermes CLI's `/browser connect` attaches via local CDP; do not assume that CLI command runs in the Desktop chat UI. Search tools are preferable for simple retrieval; visible browser interaction is for dynamic sites or user-supervised account actions.
8. Perplexity: the web application at https://www.perplexity.ai can be used by the user in a browser. Hermes already has built-in web search/extraction tools when enabled; check those before installing a separate client or requesting a Perplexity API key. Do not install unofficial Perplexity clients. The official Perplexity Portable Computer local model needs at least 24 GB VRAM on supported Linux RTX systems; do not propose local inference on this RTX 3060 12 GB machine.
9. Finish with a compact report: done, files/URLs changed, checks actually passed, what's not tested, and the next useful work step.

## Success criteria

A successful setup does NOT mean merely running fake diagnostics. The workflow should be ready to accept a real user task, use research and execution roles as needed, verify results, and preserve the important outcome in the project knowledge base.
