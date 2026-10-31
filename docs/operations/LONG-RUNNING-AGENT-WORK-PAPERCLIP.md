# Long-running agent work — Hermes + Claude Code + Paperclip

Date: 2026-10-31  
Status: **DESIGN / PLANNED** — no local scan, Paperclip installation or adapter configuration performed by this document's author.

## Purpose

Move from short prompt/response experiments to sustained, accountable work by two agents. Every long task must have:
- one clear objective and owner per work package;
- bounded read/write permissions;
- phases and checkpoints;
- persistent task state so work resumes rather than restarting;
- evidence, outputs, elapsed time and unresolved issues;
- a reviewer who checks the first agent's result;
- human approval for destructive or externally visible actions.

Paperclip is the orchestration layer, not the model host. It manages agent roles, tasks, goals, schedules/heartbeats, budgets, approvals and run history.

## Current local architecture

Last verified state:
- one Unsloth llama-server;
- one Qwen3.5-9B-Q4_K_M model;
- one server slot (`--parallel 1`);
- Hermes and Claude Code are independent clients to the same endpoint;
- context target 160K.

Implication: scheduling both agents' full audits at the same time does not create two concurrent model generations. Requests contend for the one slot. For sustained work on this workstation, stagger agent heartbeats and execute long tasks sequentially. Parallelize only independent non-inference operations if they do not compete for RAM, disk or the single model endpoint.

## Paperclip status and fit

Current Paperclip release page shows v2026.1023.0 released 2026-10-23. Official documentation lists these built-in adapters:
- `hermes_local`: starts the local Hermes CLI for a heartbeat; default adapter timeout is 300 seconds, `persistSession` defaults to true, and toolsets can be selected. The example config exposes `maxIterations`, `timeoutSec`, `persistSession`, `enabledToolsets`, and environment overrides.
- `hermes_gateway`: calls a running Hermes API server over HTTP/SSE. It requires an enabled Hermes API server; do not assume the currently running Gateway UI/service is automatically that API endpoint.
- `claude_local`: starts Claude Code locally; session IDs persist across heartbeats; configurable `timeoutSec` (0 means no process timeout), `maxTurnsPerRun` (documented default 300), `cwd`, `model`, and `env`.

Official sources:
- Paperclip releases: https://github.com/PaperclipAI/paperclip/releases
- Core concepts / heartbeat / adapter types: https://docs.paperclip.ing/guides/welcome/key-concepts/
- Hermes adapter: https://github.com/paperclipai/paperclip/blob/master/packages/adapters/hermes/README.md
- Claude Code adapter: https://github.com/paperclipai/paperclip/blob/master/docs/adapters/claude-local.md
- Heartbeat protocol: https://github.com/paperclipai/paperclip/blob/master/docs/guides/agent-developer/heartbeat-protocol.md

### Critical compatibility question before overnight use

The current agents use a custom local Unsloth endpoint. The Claude adapter supports per-agent `env`, but its actual `ANTHROPIC_BASE_URL` and model routing must be smoke-tested. The Hermes local adapter spawns Hermes CLI and accepts model/provider overrides, but Paperclip's documented provider list and the Hermes custom provider path need to be reconciled with this exact installation. The gateway adapter is another possibility, but it requires an explicitly enabled Hermes API server endpoint.

Therefore:
1. Verify installed Paperclip version and adapter forms.
2. Test each adapter in isolation against the existing local Qwen route.
3. Confirm that neither adapter silently switches to a cloud model.
4. Confirm the single Unsloth server remains the only model process.
5. Only then enable scheduled/overnight heartbeats.

Do not modify the working model route or create a second model server to make Paperclip onboarding easier.

## Long-running HOME audit — work packages

This is deliberately more substantial than a quick `du` report. It should create a useful baseline for future workstation maintenance and agent-company operations.

### Package A — Hermes: storage and filesystem inventory

Read-only scope:
- map home-directory top-level layout and expand the largest branches to depth 3;
- measure directory sizes on the same filesystem without crossing mounts;
- inventory the largest 50 files above 500 MiB using metadata only;
- list model files by name, quant, size and path in approved model directories;
- inventory ISO, archive, build, backup and cache categories;
- identify likely duplicate candidates by exact filename/size only; do not hash every large file;
- collect filesystem capacity and free space;
- produce a ranked storage pressure report with measured evidence.

Sensitive paths and content:
- Never read password files, secrets, tokens, credentials, browser profiles, SSH/GPG keys, private messages or personal document contents.
- Do not enumerate contents of `~/.ssh`, `~/.gnupg`, `~/.pki`, `~/.config`, `~/.password-store`, `~/.aws`, `~/.azure`, `~/.kube`, `~/.docker`, browser profiles, or secret directories.
- `~/.hermes`: only aggregate size of `models`; never read configs, auth, keys, logs or voice secrets.
- `~/.cache` and `~/.local/share`: aggregate sizes only.
- Do not read personal files in Documents/Downloads; use path, size, timestamp and extension metadata only.
- Never delete, move, rename, chmod, chown, edit, install or download anything.
- Do not follow symlinks or cross filesystem/mount boundaries.

Deliverable:
`HOME_STORAGE_AUDIT_HERMES.md` in its own task workspace or local report path, not automatically committed to GitHub.

### Package B — Claude Code: projects and development-workspace inventory

Read-only scope:
- identify project/repository roots under approved workspaces (for example `~/projects` and known working directories);
- for each Git repository, capture project path (redacted to a stable project label for publication), branch name, clean/dirty status and ahead/behind counts where available;
- do not print remote URLs, credential-bearing URLs, local usernames or untracked file names in public reports;
- identify large `node_modules`, `dist`, `build`, `.venv`, `target`, `vendor`, generated ISO and build-output directories by aggregate size;
- read only project README and manifest files when needed to infer project purpose; do not inspect secret/config files or personal documents;
- identify abandoned-looking copies or duplicate project roots as candidates only, never as safe-to-delete facts;
- create an actionable map of active projects, unknown projects, build artifacts and storage hotspots.

Deliverable:
`HOME_PROJECTS_AUDIT_CLAUDE.md` in its own task workspace or local report path, not automatically committed to GitHub.

### Package C — independent sequential cross-review

After both reports exist:
1. Claude Code checks Hermes' numeric claims, missing branches and unsafe cleanup recommendations.
2. Hermes checks Claude Code's project map, status interpretation and unsubstantiated conclusions.
3. Each reviewer must cite the exact evidence/path/command for a disagreement.
4. Produce a joint report with three lists: agreed facts, disagreements and unresolved checks.

The cross-review must not execute writes or alter the source reports.

### Package D — action backlog, not cleanup

Create a prioritized backlog:
- P0: urgent capacity or data-loss risks supported by evidence;
- P1: high-value organization/archive opportunities;
- P2: optional cleanup after owner review;
- P3: cosmetic improvements.

Every item must include:
- exact measured size or clearly state that the size is unknown;
- why it is a candidate;
- what could break if changed;
- what backup or validation is needed;
- a proposed human approval step.

No deletion or moving is authorized by this audit.

## Long task execution protocol

Do not attempt to put the entire audit into one giant prompt/heartbeat. Break it into work sessions:

1. **Heartbeat 1:** identity, environment and top-level map; write a concise checkpoint.
2. **Heartbeat 2:** drill down into largest directories; record commands and measured sizes.
3. **Heartbeat 3:** model, ISO, archive, cache and build inventory, respecting exclusions.
4. **Heartbeat 4:** project/repository map and evidence-backed recommendations.
5. **Heartbeat 5:** resume from checkpoint, verify key numbers and produce final report.
6. **Review heartbeat:** second agent checks the first report; then reverse review.
7. **Board review:** user approves or rejects proposed changes; do not execute them automatically.

Each checkpoint must include completed phases, exact next step, output paths, and status. A heartbeat ending is not a task completion if work remains. Update the Paperclip task status/comment with a checkpoint before the run ends.

Suggested starting bounds (subject to the installed Paperclip version and actual resource behavior):
- Hermes `hermes_local`: enable session persistence; use a longer timeout than the default only after a short smoke test. The documented default timeout is 300 seconds.
- Claude Code `claude_local`: retain session persistence; set an appropriate `timeoutSec` and `maxTurnsPerRun` after measuring one test run.
- Do not set unbounded timeouts or turns before confirming stop/recovery works.
- Stagger heartbeats rather than waking both agents at the same minute while the local model has one slot.

## What the first overnight Paperclip pilot should look like

Company goal:
"Maintain a safe, evidence-backed map of the workstation and its projects so the agent team can plan useful work without losing data or changing the machine without approval."

Suggested roles:
- Hermes — Operations / storage analyst.
- Claude Code — Engineering / repository analyst and independent reviewer.
- Human owner — board; approves scope, budgets, any writes, cleanup, external publishing and agent hires.

Pilot task:
"Build the HOME storage and project baseline, produce two independent reports, cross-review them, and prepare a prioritized no-change action backlog."

The first overnight pilot should be read-only and produce durable outputs. Do not authorize automatic cleanup, package installation, model downloads, Git pushes, system configuration changes or external messages.

## Comparison measurements

For every run capture:
- agent, adapter and Paperclip version;
- model/profile and inference endpoint (never record keys);
- start/end timestamps and heartbeat count;
- model slot waiting time, if observable;
- actual filesystem scan time separate from model reasoning time;
- tool calls / commands executed;
- output files and line counts;
- errors/timeouts/retries;
- measured accuracy on a small set of manually checked directory sizes;
- reviewer findings / correction count.

Interpret results carefully: both clients use the same model and one server slot. This experiment compares their tool orchestration, persistence, reporting and recovery—not two different model brains.

## Acceptance gate before unattended overnight tasks

All must pass:
- Paperclip install/version confirmed and backed up.
- Hermes and Claude adapters each pass a harmless local smoke test.
- Both route to the intended Qwen endpoint; no cloud fallback is silently selected.
- The model server stays singular; no second Qwen process.
- Task/session resumes across heartbeats.
- Timeout and Stop controls are verified.
- Task logs and workspace paths are understood.
- Sensitive data exclusions work.
- Budget and heartbeat schedule are set conservatively.
- Destructive and externally visible actions remain approval-gated.

Only after this gate should the team receive unattended overnight tasks.

## Status

- HOME audit protocol: designed, not run.
- Hermes/Claude local adapters: supported by Paperclip documentation, not yet verified on the user's installation.
- Shared custom Qwen routing inside both Paperclip adapters: **UNKNOWN / requires adapter smoke tests**.
- Overnight autonomy: **NOT ENABLED**.
