# Rules
- Never use curl or similar to query GitHub API, always use the gh CLI
- When I say 'commit', commit only the changes relevant to this thread with a semantic commit msg, always check the working tree first (beware other agents may have commited since)
- Make sure all commits are GPG signed, when it times out stop and tell me to say continue to try it again
  - Exception: When doing a merge of another branch use Git's default commit message
- When solving issues add a resolves #n to the commit message body
- Use pnpm if the project already uses it, otherwise use bun
  - Never use npm or yarn
- Always strive for concise, simple solutions
- If a problem can be solved in a simpler way, propose it
- TypeScript: Never use `any` unless 100% necessary or specifically instructed
- Don't run dev server commands (e.g., `bun run dev`)
- Don't run build commands unless specficially told to
  - Exception: When you need to run a build to reproduce or verify tests it is allowed
- Focus on checking commands like `bun run typecheck`, `bun run lint`, etc.
- If you need to run anything as root, use pkexec or stop and ask the user to run everything you need to continue

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
