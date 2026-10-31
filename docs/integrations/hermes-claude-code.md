# Hermes and Claude Code integration

Research date: 2026-10-31. Decision: do not configure an additional integration yet.

The current local setup already has two independent clients (Hermes and Claude Code) connected to one Qwen3.5-9B model through the same Unsloth API endpoint. With `--parallel 1`, requests share one slot and run sequentially. Sharing an inference endpoint does not share conversation history or create agent-to-agent orchestration.

## Supported options

1. **Import Claude Code settings into Hermes.** The official `hermes import-agent claude-code --dry-run` preview can inspect transferable instructions, Bash permissions, MCP server definitions and skills. This is a one-time configuration import, not live synchronization. Secrets and credential files are not imported. Source: https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/import-from-other-agents.md

2. **Expose Hermes tools to Claude Code over MCP.** The official `mcp-serve` plugin lets Claude Code access selected Hermes capabilities, including messaging conversations and connected messaging platforms; optional tools include web/browser, vision, image generation, skills and TTS. Current plugin setup is documented at https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp . The current plugin spelling is `hermes mcp-serve`; the older `hermes mcp serve` was moved to the plugin.

3. **Use Claude as Hermes' model provider.** Hermes can route inference to Anthropic/Claude, including documented Claude Code credential-store integration. This changes the model provider; it does not connect the two agent clients. Source: https://hermes-agent.nousresearch.com/docs/integrations/providers

4. **Hermes ACP mode.** `hermes acp` exposes Hermes to ACP-compatible editor hosts such as VS Code or Zed. This is editor integration, not direct agent-to-agent wiring with Claude Code. Source: https://hermes-agent.nousresearch.com/docs/user-guide/features/acp

## Recommendation

Do not install or change anything yet. Keep Hermes and Claude Code independent for the current Screenlife comparisons. MCP does not increase inference throughput, and the single server slot remains shared. If a concrete use case appears later, evaluate a one-way Claude Code -> Hermes MCP connection with only the required tools enabled. Do not import or replace settings without a preview and review.
