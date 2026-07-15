# Rules
- Never use curl or similar to query GitHub API, always use the gh CLI
- When I say 'commit', commit only the changes relevant to this thread with a semantic commit msg, always check the working tree first (beware other agents may have commited since)
- Exception: When doing a merge of another branch use Git's default commit message
- Use pnpm if the project already uses it, otherwise use bun
- Never use npm or yarn
- Always strive for concise, simple solutions
- If a problem can be solved in a simpler way, propose it
- TypeScript: Never use `any` unless 100% necessary or specifically instructed
- Don't run dev server commands (e.g., `bun run dev`)
- Don't run build commands unless specficially told to
- Focus on checking commands like `bun run typecheck`, `bun run lint`, etc.

# RTK - Rust Token Killer (Codex CLI)

**Usage**: Token-optimized CLI proxy for shell commands.

## Rule

Always prefix shell commands with `rtk`.

Examples:

```bash
rtk git status
rtk cargo test
rtk npm run build
rtk pytest -q
```

## Meta Commands

```bash
rtk gain            # Token savings analytics
rtk gain --history  # Recent command savings history
rtk proxy <cmd>     # Run raw command without filtering
```

## Verification

```bash
rtk --version
rtk gain
which rtk
```
