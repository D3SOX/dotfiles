# Rules

- Never use curl or similar to query GitHub API, always use the gh CLI
- When I say 'commit', commit only the changes relevant to this thread with a semantic commit msg, always check the working tree first (beware other agents may have commited since)
  - Exception: When doing a merge of another branch use Git's default commit message
- Make sure all commits are GPG signed, when it times out stop and tell me to say continue to try it again
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
- If something is not entirely clear to you, prefer asking a clarification question. Especially when there could be multiple ways to interpret the message (The user is a German native speaker)

## Info
The user uses KDE Plasma (Wayland) on Arch Linux. They prefer using privacy-respecting solutions. Respect that when choosing depenidencies (e.g. use Bunny Fonts instead of Google Fonts)

## Command execution

- Use `rtk` when command output is likely to be large or repetitive and a
  filtered summary is sufficient. Good candidates include test suites, builds,
  linters, logs, broad searches, dependency listings, and infrastructure
  status commands.
- Use raw commands when output is expected to be short, when exact or complete
  output matters, or when inspecting a specific file or narrowly scoped result.
- In command chains, apply `rtk` only to segments that benefit from filtering.
- If RTK hides needed detail, rejects a command or flag, or complicates
  debugging, rerun the command raw. Do not use `rtk proxy` merely to satisfy an
  RTK convention.
- If a task is primarily Bash or command-line automation, consider RTK for
  noisy validation commands, but keep commands raw when validating exact
  stdout, stderr, exit-status, quoting, or pipeline behavior.
- Prefer running code, tests, linters, and type checks over guessing.
- Read complete errors, logs, and stack traces before fixing them.
