# Benchmark protocol — models, inference performance and agent quality

Status: ACTIVE WORKING METHOD  
Created: 2026-10-31

Use benchmarking frequently whenever comparing, selecting, upgrading, quantizing or reconfiguring a model for the user's local AI stack.

## Distinguish three kinds of benchmark

### 1. Model capability benchmarks
Use standard evaluation suites (for example MMLU, GSM8K, HumanEval, TruthfulQA and relevant coding/reasoning tests) to compare reasoning, knowledge, coding and truthfulness. These do not measure the complete local runtime, and they do not establish that an agent will use tools reliably.

Hermes ecosystem skill: `evaluating-llms-harness` (lm-eval-harness integration). Treat it as a possible tool for standardized quality evaluation, after checking dependencies, model compatibility and available compute. Do not install or run it automatically on the user's constrained machine.

### 2. Local inference performance benchmarks
Measure the actual model/server on the user's target hardware:
- time to first token (TTFT);
- prompt processing / prefill throughput (tokens/s);
- generation throughput (tokens/s);
- prompt length and generated token count;
- peak VRAM and system RAM;
- CPU/GPU offload placement;
- KV-cache placement and memory use;
- context length actually accepted by the server;
- stability at the target context, including 160K where that remains the requirement;
- errors, crashes, swapping, and timeouts.

Record exact model file, quantization, file size, checksum, runtime version, server command line, GPU/CPU settings, context, parallel slots, and test date. Run repeated trials where practical and report median plus range, not a single best result.

### 3. Agent workflow benchmarks
Run identical tasks through the same agent/client route used in production:
- Hermes and Claude Code separately;
- same system/task prompt and equivalent tools/permissions;
- same server endpoint and model, unless model/provider is the variable under test;
- same repository snapshot or controlled fixture;
- tool-call validity and completion rate;
- factual/coding correctness, omissions and unsafe actions;
- number of tool calls and retries;
- elapsed wall-clock time;
- final artifact quality.

Use existing Screenlife sessions (system audit, autumn leaves, Amsterdam weather) as early reference cases, but do not treat their provisional conversational scores as objective benchmark scores. Preserve raw outputs/tool traces and mark transcription gaps or truncation.

## Method for the user's current architecture

Current baseline (last verified 2026-10-31):
- Qwen3.5-9B-Q4_K_M GGUF.
- One Unsloth llama-server.
- Hermes and Claude Code are independent clients.
- `--parallel 1`; therefore requests are serialized through one slot.
- Context target: 160000.
- Hardware: RTX 3060 12 GB VRAM, approximately 12 GB system RAM, 4 GB swap.

When changing only the model, hold the client architecture and server settings as constant as possible. When hardware limitations force a setting to change, record that as a separate variable; do not compare results as though it were a pure model comparison.

## Benchmark order for larger model selection

1. Keep the working Qwen3.5-9B setup unchanged as baseline.
2. Read-only inventory existing models first; do not download a duplicate.
3. Test one model/server at a time. Never keep two large model copies resident on the RTX 3060 without a deliberate memory check.
4. Do not lower the established 160K context automatically to make a candidate fit. A model that cannot sustain the required context should be marked as a failed fit for this use case.
5. Capture actual memory placement and peak memory, not just the GGUF file size.
6. Use a short smoke test first, then the controlled task suite.
7. Compare quality and speed separately. Do not assume more parameters means better agent performance or higher throughput.
8. Preserve failed results; they explain why a candidate was rejected.

## About `benchmark-models` / gstack

The public `benchmark-models` skill found in the gstack catalogue is designed to run the same gstack-skill prompt across Claude, GPT via Codex CLI, and Gemini, comparing latency, tokens, cost and optional LLM-judge quality. It is useful for cloud-model comparisons in its intended environment, but it is not automatically a benchmark harness for the user's local Qwen/Unsloth endpoint.

Do not install or run it without verifying its actual SKILL.md, dependencies, model routes and whether it can target a custom local OpenAI-compatible endpoint. Its name alone does not prove compatibility with Hermes, Claude Code's current local Qwen route or jcode.

## Reporting template

```text
BENCHMARK:
DATE:
MODEL / GGUF:
QUANT:
SHA256:
RUNTIME / VERSION:
CLIENT / VERSION:
SERVER ARGS:
CONTEXT:
PARALLEL:
HARDWARE:
PROMPT TOKENS:
OUTPUT TOKENS:
TTFT:
PREFILL TOKENS/SEC:
GENERATION TOKENS/SEC:
PEAK VRAM:
PEAK SYSTEM RAM:
KV CACHE / OFFLOAD:
TOOL CALLS / SUCCESSES:
TASK CORRECTNESS:
WALL-CLOCK TIME:
REPEATS / MEDIAN / RANGE:
ERRORS / LIMITATIONS:
STATUS: VERIFIED | OBSERVED | FAILED | NOT TESTED
RAW OUTPUT / TRACE PATH:
NEXT ACTION:
```

## Sources

- gstack `benchmark-models` description: https://agentskillhub.dev/u/garrytan/sk/benchmark-models
- gstack skill catalogue: https://www.openruna.com/skills/gstack-benchmark-models
- Hermes `evaluating-llms-harness` skill listing: https://agentmods.dev/skills/nousresearch/hermes-agent/evaluating-llms-harness
- Hermes official documentation: https://hermes-agent.nousresearch.com/docs
