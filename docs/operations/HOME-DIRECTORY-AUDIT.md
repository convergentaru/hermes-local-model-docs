# Home-directory audit — Hermes vs Claude Code

Date: 2026-10-31  
Status: **PLANNED — read-only audit; no local scan has been executed by this document's author.**

## Purpose

Compare Hermes and Claude Code on the same bounded audit of the user's Ubuntu home directory. Both currently use the same local Qwen model through one Unsloth server with `--parallel 1`.

This is two kinds of test:
1. a tiny simultaneous request to observe how the clients behave when they contend for one model slot;
2. a proper independent home inventory, run sequentially by each agent with the same prompt, followed by cross-review.

## What one slot means

The confirmed Unsloth server has `--parallel 1`. In llama.cpp, `--parallel N` sets the number of server slots. The `/slots` endpoint reports per-slot processing state and can return HTTP 503 when no free slot exists if `fail_on_no_slot=1` is requested.

Therefore, two simultaneously launched clients do **not** get two concurrent model generations with the current configuration. One request may occupy the slot while the other waits or encounters a client/server timeout depending on request handling. Do not infer from two open terminals that inference is parallel.

Official reference: https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md

## Phase 0 — small concurrency probe

Start two **new, short sessions** (Hermes and Claude Code) as close together as practical. Send the same no-tools prompt to both:

```text
Reply with exactly: HOME_AUDIT_SLOT_TEST_OK
Do not call tools. Do not add any explanation.
```

Record for each:
- time the request was submitted;
- time the answer completed;
- whether it answered normally, waited, timed out, or returned an error;
- exact error text if any;
- whether the other client was still waiting.

This probe uses only a tiny response. It is a scheduling/contestion check, not a performance benchmark of model quality.

## Phase 1 — same read-only home audit, sequential

Run the exact same prompt below first in Hermes, then in Claude Code (or reverse the order in a repeat trial). Do not launch the full audits concurrently with `--parallel 1`.

### Shared audit prompt

```text
HOME DIRECTORY AUDIT — READ ONLY

Inspect the user's home directory ($HOME) and produce a practical storage/organization report.

STRICT SAFETY:
- Read-only only. Do not create, edit, move, rename, delete, chmod, chown, install, download, or upload anything.
- Do not open or read document contents, source files, browser history, chat databases, credentials, tokens, keys, password stores, or environment files.
- Do not inspect contents of: ~/.ssh, ~/.gnupg, ~/.pki, ~/.config, ~/.password-store, ~/.aws, ~/.azure, ~/.kube, ~/.docker, browser profiles, or secret/credential directories.
- For ~/.hermes, do not inspect config, auth, credentials, logs, or voice secrets. You may report the aggregate size of ~/.hermes/models only; do not read model contents.
- For ~/.cache and ~/.local/share, report aggregate directory size only. Do not enumerate their contents.
- Do not follow symlinks or cross into other mounted filesystems.
- Inspect directory structure only to depth 2; list at most 30 largest files above 1 GiB outside excluded paths, using metadata only. Never open files.
- Do not calculate hashes or scan all file contents.
- If a path is missing or inaccessible, say so. Never guess.

REPORT:
1. Home filesystem capacity/free space (metadata only).
2. Top-level directory sizes, with emphasis on Documents/Документы, Downloads/Загрузки, projects, models and other large directories that actually exist.
3. Largest files over 1 GiB: path, size and file type if available from metadata. Avoid showing secret-looking filenames; report their aggregate size instead.
4. Large caches, model collections, ISO images, archives and obvious backup/build folders.
5. Likely cleanup/reorganization candidates, clearly labelled as REVIEW ONLY. Do not claim a file is safe to delete.
6. Three to seven prioritized recommendations, with estimated space impact only when supported by measured sizes.
7. Risks, unknowns and commands actually executed.
8. Your own elapsed time, separating filesystem scan time from model response/analysis time where possible.

Keep the report concise (maximum about 80 lines). Distinguish VERIFIED, OBSERVED, INFERRED and UNKNOWN. Do not make changes and do not publish anything to GitHub from the local agent session.
```

## Phase 2 — cross-review

After both independent reports are received:
1. Give the Hermes report to Claude Code and ask it to identify unsupported claims, missed directories and recommendations not backed by measured data. Ask for read-only checks only.
2. Give the Claude Code report to Hermes and ask for the same independent critique.
3. Reconcile the two reports. Keep disagreements visible; do not force a consensus.

## Fairness and interpretation

- Both agents must use the same task prompt and directory exclusions.
- Prefer fresh sessions; if not possible, record that the preceding conversation history may affect context and response time.
- The second full audit may benefit from the operating-system file cache warmed by the first. Separate filesystem scan time from model reasoning time; do not treat a small total-time difference as proof that one agent is inherently faster.
- Both agents use the same Qwen model. This compares client orchestration, tool use, reporting and resilience—not the underlying model's intelligence.
- A one-slot concurrency probe tests waiting/error handling. It does not prove that the full audits should be run simultaneously.
- Keep original reports in the chat until reviewed. Before committing any report, create a sanitized summary: do not upload private filenames, full personal paths, usernames, secrets or unrelated personal information to GitHub.

## Acceptance criteria

A useful report must be grounded in actual metadata and exact commands, not assumptions. Recommendations must not trigger automatic deletion or modification. The next step is always human review and explicit approval.


---

## Superseding long-running version — 2026-10-31

The short one-pass audit above remains a small smoke-test protocol. For the user's requested sustained work, use the expanded staged plan in:
`docs/operations/LONG-RUNNING-AGENT-WORK-PAPERCLIP.md`.

The expanded task is no longer just a shallow directory-size listing. It has separate work packages:
- Hermes: measured storage and filesystem inventory.
- Claude Code: local project/Git workspace inventory.
- Then sequential cross-review by the other agent.
- Then a human-reviewed action backlog; no cleanup is automated.

Each agent must checkpoint progress and resume in later Paperclip heartbeats where necessary. Keep the one-slot constraint in mind: stagger agent runs; do not expect simultaneous inference.

The full plan contains sensitive-path exclusions, metadata-only inspection rules, output requirements, and a pre-overnight acceptance gate. Do not enable unattended overnight runs until each Paperclip adapter has passed a local-Qwen routing test and Stop/session-resume behaviour is verified.
