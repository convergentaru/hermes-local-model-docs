# Model upgrade research — Hermes + Claude Code on RTX 3060 12 GB

Research date: 2026-10-31.  
Decision: **candidate shortlist only; no download, model swap, server restart, or configuration change performed.**

## Existing setup and constraints

Last verified model setup:
- One Unsloth `llama-server`, one active Qwen3.5-9B GGUF.
- Two independent clients: Hermes (OpenAI-compatible Chat Completions) and Claude Code (Anthropic-compatible API).
- One shared inference slot (`--parallel 1`), so the agents' requests are serialized.
- Unsloth context was configured to 160000.
- Hardware: NVIDIA RTX 3060 12 GB VRAM; system RAM approximately 12 GB; 4 GB swap.

Preserve this as the known-good baseline. Do not run two large model servers in parallel. Do not delete or replace the 9B GGUF. Do not lower the established 160K context target without an explicit decision.

## Primary new candidate: Qwen3.8-27B GGUF

Unsloth's model page explicitly lists both Hermes Agent and Claude Code as supported launch targets for Qwen3.8-27B. It describes the model as a 27B hybrid-thinking model for agentic coding and chat, with nested tool calls, vision input and a native 256K context.

Official Unsloth page:
https://unsloth.ai/models/qwen3.8-27b

GGUF repository:
https://huggingface.co/unsloth/Qwen3.8-27B-GGUF

Observed quant file sizes from the official Unsloth repository:

| Quant | File size |
|---|---:|
| UD-IQ2_XXS | 7.27 GB |
| UD-IQ2_S | 8.37 GB |
| UD-Q2_K_XL | 9.83 GB |
| UD-IQ3_XXS | 10.9 GB |
| UD-IQ3_S | 12.0 GB |
| UD-Q3_K_XL | 13.1 GB |
| UD-IQ4_XS | 14.3 GB |
| UD-Q4_K_S | 15.4 GB |
| UD-Q4_K_M | 16.5 GB |
| UD-Q4_K_XL | 17.6 GB |

The model page summarizes the preferred 4-bit configuration as requiring approximately 17–19 GB total RAM+VRAM. Its table lists 13–16 GB for 3-bit and 11–13 GB for 2-bit. The size of the GGUF alone does not establish that the complete runtime, KV cache, context and desktop will fit.

### Candidate to test first if the local inventory confirms feasibility

- `UD-Q3_K_XL`, 13.1 GB: first quality-oriented compromise to evaluate on this 12 GB VRAM + approximately 12 GB RAM system.
- `UD-IQ3_XXS`, 10.9 GB: smaller fallback, with a more aggressive quantization trade-off.
- 4-bit `UD-Q4_K_XL`, 17.6 GB: preferred by the Unsloth page for quality, but riskier for available RAM/VRAM and long-context overhead on this machine.

Do not assume any of these will retain 160K context until actual Unsloth/llama-server memory placement and functional tests confirm it. The established 160K target remains the preferred acceptance criterion; do not silently lower it.

Important platform detail: the model page says to use GGUF on most computers and NVFP4 on NVIDIA Blackwell-class hardware (RTX 50 series, DGX Spark, B200/B300). The user's RTX 3060 is not a Blackwell GPU; select GGUF, not the NVFP4 artifact.

Unsloth lists these integration examples:
- Claude Code: `unsloth start claude --model unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL`
- Hermes: `unsloth start hermes --model unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL`

These examples prove that both integrations are supported by Unsloth. Do **not** paste them blindly into the already working architecture: the current setup starts one API-only Unsloth server and points both clients at it. Preserve the single-server arrangement and reuse the existing client attachment method.

## Candidate from the user's previously used collection: Qwen3.6-35B-A3B

This model appeared in the user's earlier local setup:
`Qwen3.6-35B-A3B-UD-IQ2_XXS.gguf`

Official Qwen model card:
https://huggingface.co/Qwen/Qwen3.6-35B-A3B

Official Unsloth GGUF repository:
https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF

Model architecture: 35B total parameters, approximately 3B active parameters; native context 262,144. Unsloth's `UD-IQ2_XXS` file is approximately 10.8 GB.

This is an attractive existing-collection candidate because it is a mixture-of-experts model and the user's prior history mentions a previous setup with this exact quant. Its current local presence, file integrity, actual runtime parameters and current compatibility must be verified before relying on that old record. The 2-bit quant is an important quality compromise; do not mistake 35B total parameters for 35B active compute or assume it is automatically superior to a well-quantized dense 27B.

## Why not choose by B-count alone

Compare models on the actual work expected from the agents:
- reliable native tool calls and nested tool calls;
- repository-level coding and multi-step reasoning;
- quality of Russian technical explanations and translations;
- ability to use tools without malformed JSON/tool schemas;
- response speed after the prompt is already loaded;
- stability at 160K context;
- RAM and VRAM peak, not just model-file size.

The 35B-A3B MoE has only about 3B active parameters per token, whereas Qwen3.8-27B is dense. Their inference speed cannot be predicted from total parameter count alone.

## Proposed controlled evaluation

1. Read-only inventory of existing local GGUF files and Unsloth collection; do not download anything until the existing 35B-A3B status is known.
2. Preserve the currently working 9B model and its configuration untouched.
3. Test only one model server at a time; do not keep two model copies resident on the RTX 3060.
4. If the previously used Qwen3.6-35B-A3B file exists, validate its metadata and run a short functional test with the same server architecture.
5. Evaluate Qwen3.8-27B UD-Q3_K_XL as the primary new candidate only if the memory estimate is feasible. Download a separate file; never overwrite the baseline.
6. Keep the target context at 160K for acceptance. Record actual `-c`, KV placement and memory. If the candidate cannot sustain the required context without swapping or severe slowdown, mark it as a failed fit rather than quietly reducing the context.
7. Compare Hermes and Claude Code using identical prompts previously used in the Screenlife session: system audit, technical explanation / translation, and a repository task. Measure prompt-processing time and generation tok/s separately, plus tool-call success and final correctness.
8. Keep the chosen shared-server design, one active llama-server and one slot unless evidence motivates a separate architectural decision.

## Recommendation

Primary new model to investigate: **Qwen3.8-27B UD-Q3_K_XL**.  
First no-download check: **Qwen3.6-35B-A3B UD-IQ2_XXS** from the user's previously used collection.

No changes were made to the running setup during this research.

## Sources

- Unsloth Qwen3.8-27B overview and Hermes/Claude Code support: https://unsloth.ai/models/qwen3.8-27b
- Unsloth Qwen3.8-27B GGUF quant files: https://huggingface.co/unsloth/Qwen3.8-27B-GGUF
- Qwen3.6-35B-A3B model card and active parameters: https://huggingface.co/Qwen/Qwen3.6-35B-A3B
- Unsloth Qwen3.6-35B-A3B GGUF quant files: https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF
- Hermes local model fit and recommendation logic: https://hermes-agent.nousresearch.com/docs/user-guide/local-models
- llama.cpp function-calling and Jinja support: https://github.com/ggml-org/llama.cpp/blob/master/docs/function-calling.md
