# Copy/paste tasks — long-running HOME audit

Use these as separate assigned tasks. Do not launch both full tasks at the same time while the Unsloth server has one slot. Run Hermes first, then Claude Code. After both reports exist, run the cross-review prompt in both directions.

## Task 1 — Hermes: storage and filesystem operations audit

```text
TASK: HOME-OPS-001 — Storage and filesystem inventory
ROLE: Operations / Storage Analyst
MODE: READ-ONLY

You are doing a substantial, evidence-backed workstation audit, not a quick summary. Work through every phase below. Do not stop after a top-level directory listing.

SCOPE:
- Audit $HOME on the Ubuntu workstation.
- Stay on the home filesystem; do not cross mounted filesystems or follow symlinks.
- Inspect directory structure to depth 3, expanding the 10 largest safe directories to depth 4 only when it materially improves the report.
- Measure top-level and large-directory sizes.
- Inventory up to 50 largest files over 500 MiB using metadata only.
- Inventory GGUF model filenames, quantization labels when visible in the filename, sizes and directory location only in approved model folders.
- Inventory ISO, archives, backups, VM images, build outputs and large caches by path/size/category.
- Find possible duplicates using filename + size + timestamp metadata; do not hash huge files.

STRICT PRIVACY:
- Never read contents of Documents/Документы, Downloads/Загрузки, photos, videos, chat exports, email stores or personal files.
- Never inspect contents of ~/.ssh, ~/.gnupg, ~/.pki, ~/.config, ~/.password-store, ~/.aws, ~/.azure, ~/.kube, ~/.docker, browser profiles or credentials directories.
- For ~/.hermes, report only aggregate size of ~/.hermes/models and model filenames/sizes in that approved directory. Do not read Hermes configs, auth, API keys, logs, session databases, voice model configs or secrets.
- For ~/.cache and ~/.local/share, report aggregate size only.
- Do not list secret-looking filenames. Report only aggregate sizes for sensitive directories.
- Do not send private filenames or personal paths to public GitHub.

SAFETY:
- Do not delete, move, rename, edit, chmod, chown, install, download, upload, launch services or change configuration.
- Do not run filesystem repair, cleanup tools or package-manager operations.
- Do not read file contents except non-secret filesystem metadata.
- If a directory is inaccessible, report it as inaccessible; do not escalate privileges.

PHASES:
A. Filesystem capacity, mounts relevant to HOME, free space.
B. Top-level directory map and sizes.
C. Drill-down into largest safe branches; identify actual storage hotspots.
D. Models, ISO images, archives, backups and build artifacts.
E. Duplicate candidates and obvious stale/temporary data — candidates only, never mark safe to delete.
F. Ranked recommendations with measured space impact, risk and required human approval.
G. Verify key measurements with a second command before finalizing.

CHECKPOINTS:
- After each phase, report a short checkpoint in this task.
- If the execution window ends, save exact completed phases, next phase, findings and paths; resume from the checkpoint without repeating completed scans.
- Do not fabricate an artifact if nothing was saved. Use the Paperclip task thread/artifact workspace for report persistence when available.

FINAL REPORT:
- Separate VERIFIED, OBSERVED, INFERRED and UNKNOWN.
- Include exact commands actually run.
- Include measured sizes, free space, and timestamp.
- List the 15–25 highest-value findings, not a wall of filenames.
- Provide 7–10 prioritized recommendations; include estimated recoverable space only where measured.
- Explain what should NOT be touched.
- Record elapsed filesystem scan time separately from model reasoning time.
- State any command that failed and its exact error.
- No changes have been authorized; end with the next safe action only.
```

## Task 2 — Claude Code: engineering workspace and repository audit

```text
TASK: HOME-ENG-001 — Projects and development workspace inventory
ROLE: Engineering / Repository Analyst
MODE: READ-ONLY

Perform a substantial audit of local development workspaces under $HOME. This is not a code review and not a cleanup job.

SCOPE:
- Inspect known development roots such as ~/projects, ~/fcm-opencode-test and other clearly named project roots under HOME.
- Find Git repository roots to depth 4 within those approved development roots.
- For each repository, collect: project label, branch, clean/dirty state, tracked/untracked counts, ahead/behind counts if available, last commit date and top-level size.
- Do not print remote URLs, tokens, usernames, secret paths or untracked filenames in a public report.
- Inspect only README files, project indexes and non-secret manifests (package.json, pyproject.toml, Cargo.toml, go.mod) when needed to identify project purpose and status.
- Measure aggregate sizes of node_modules, dist, build, target, .venv, vendor, generated ISO, VM image and archive directories; do not inspect their contents.
- Identify duplicate-looking project clones and worktrees by path, repo identity and aggregate size; do not assume one is safe to delete.
- Distinguish active, archived, unknown and potentially abandoned projects, with evidence.

EXCLUSIONS:
- Never inspect ~/.ssh, ~/.gnupg, ~/.pki, ~/.config, ~/.password-store, ~/.aws, ~/.azure, ~/.kube, ~/.docker, browser profiles, credential files, .env files or private keys.
- Do not read personal Documents/Downloads.
- Do not inspect contents of ~/.hermes except approved model filenames/sizes if needed for a project/model inventory.
- Do not open customer data, messages, photos, email or private exports.

SAFETY:
- No writes, edits, cleanup, deletes, moves, renames, chmod/chown, dependency installs, downloads, builds or test suites.
- Do not run git reset, clean, checkout, stash, pull, fetch, commit or push. Use read-only Git commands only.
- Do not read full source trees. Limit project-purpose review to README/index and manifests.
- Do not expose remote URLs or local usernames in the report.

PHASES:
A. Identify approved workspace roots and repository roots.
B. Inventory Git status and branches without mutating repositories.
C. Measure build and dependency directory sizes.
D. Map active/archived/unknown projects from README/index metadata.
E. Identify duplication, stale build output and storage-risk candidates.
F. Draft recommendations for project organization, backups and preservation.
G. Recheck every recommendation against exact evidence.

CHECKPOINTS:
- Report a checkpoint after each phase.
- If a run window ends, record completed phases, the next exact task and evidence already gathered. Resume from the checkpoint; never restart the audit from zero.
- Persist the report in the Paperclip task thread/artifact workspace when available.

FINAL REPORT:
- Separate VERIFIED, OBSERVED, INFERRED and UNKNOWN.
- Provide repository count and project map by stable project labels.
- List only actionable findings, not a huge dump of paths.
- Include Git dirty/clean counts and important uncommitted-work warnings.
- Quantify build/dependency storage where measured.
- Recommend 7–10 actions, each with benefit, risk and required approval.
- Record exact commands, failures and elapsed scan time.
- End with a next-safe-action list. No changes are authorized.
```

## Task 3 — cross-review

```text
TASK: HOME-REVIEW-001 — Independent review of another agent's HOME audit
MODE: READ-ONLY REVIEW

Read the other agent's report and check it against available evidence. Do not repeat the entire home scan. Challenge:
1. unsupported sizes or estimates;
2. recommendations that assume files are safe to delete;
3. missed large directories or repositories;
4. hidden/mounted paths accidentally crossed;
5. secret or personal data accidentally exposed;
6. confusing file size with reclaimable space;
7. confusing uncommitted Git changes with disposable files;
8. duplicated or stale project claims without evidence.

Where possible, run narrow read-only commands to verify the disputed fact. Do not modify anything.

Return:
- confirmed findings;
- corrections;
- unsupported claims;
- overlooked risks;
- recommendations to remove or downgrade;
- exact checks performed;
- final confidence by section.

Do not force agreement. Preserve disagreements with the original report.
```

## How to run

1. Open fresh Hermes session and run Task 1. Let it proceed through checkpoints.
2. When Hermes finishes, open fresh Claude Code session and run Task 2.
3. Give the Claude report to Hermes for Task 3.
4. Give the Hermes report to Claude Code for Task 3.
5. Bring both original reports and both reviews back for a joint comparison.
