---
name: agent-browser
description: Usage guide for the agent-browser CLI. Load before running any `agent-browser` command.
allowed-tools: Bash(agent-browser:*)
hidden: true
---

# agent-browser

Fast browser automation CLI for AI agents. Chrome/Chromium via CDP with accessibility-tree snapshots and compact `@eN` element refs.

`agent-browser` and Chromium come from system packages. If `agent-browser` is not on `PATH`, skip this skill. Never install it or a browser yourself (`npm i -g agent-browser`, `agent-browser install`), even when a guide below says to.

## Start here

This file is a discovery stub, not the usage guide. Before running any `agent-browser` command, load the actual workflow content from the CLI:

```bash
agent-browser skills get core             # start here: the loop, waits, common tasks, troubleshooting
```

The core guide ends with a table of references to load for detailed commands and flags. Use `agent-browser skills get core --full` only when you need every reference at once; it is several times larger.

The CLI serves skill content that matches the installed version. This stub cannot change between releases, which is why it only points at `skills get core`.

## Specialized skills

Load a specialized skill when the task falls outside browser web pages:

```bash
agent-browser skills get electron          # Electron desktop apps (VS Code, Slack, Discord, Figma, ...)
agent-browser skills get slack             # Slack workspace automation
agent-browser skills get dogfood           # Exploratory testing / QA / bug hunts
agent-browser skills get derive-client     # Record a HAR, derive a standalone API client for a site
agent-browser skills get webmcp-gen        # Build and validate WebMCP tools for a page
agent-browser skills get modern-web-guidance  # Apply Modern Web Guidance, then verify the page
agent-browser skills get vercel-sandbox    # agent-browser inside Vercel Sandbox microVMs
agent-browser skills get vercel  # Protected Vercel deployments and flag overrides
agent-browser skills get agentcore         # AWS Bedrock AgentCore cloud browsers
```

Run `agent-browser skills list` to see everything available on the installed version.
