# Rules

## Git

### Triggers

- When I say 'commit', commit only the changes relevant to this thread with a semantic commit msg, always check the working tree first (beware other agents may have commited since)
  - Exception: When doing a merge of another branch use Git's default commit message
- When I say 'pr', commit to a new branch (never use prefixes) and create a PR.

### Guidelines

#### Babysitting a PR

- Keep an eye on changes to the default branch and rebase when needed. If an overlapping PR makes this one obsolete, stop monitoring, report it to the user, and ask before closing the PR unless closure was explicitly authorized.
- If a review bot leaves feedback you believe is not worth addressing, reply and resolve the comment. Format comments left on the users behalf as:
  ```md
  > [!NOTE]  
  > full-model-slug responding on behalf of Nico
  
  [actual reply]
  ```
- Prefer bundling follow up changes and review resolving commits into one push when review bots are not rate-limited.
- Poll checks and comments newer than the last push; verify each bot finding against the source before acting on it; fix real ones and dismiss false positives with a written reason; fix CI failures, distinguish real breaks from known infra flakes. If nothing is new, stay quiet.
- Before pushing a CI/review fix commit check if there is a new review from a review bot again and prefer bundling the commits into one push.
- Stop when the repo's review bots are green on the latest commit.
- Never trigger a review via comment for CodeRabbit. I have an external tool that manages the rate limit queue.

#### Creating a PR

- Use a sematic commit message style title.
- Prefer a concise, human-readable title that explains why the change matters. But somebody should also be able to get all the new user-facing changes from it.
- Use the repo's PR template if it exists.
- Open the description with a simple explanation of the problem based on the user's original prompt, then briefly explain the solution.
- Create ready-for-review PRs rather than drafts so review bots run.
- If you know for sure which model you are (most likely not just "GPT-5" but a more specific name; try to get the real model; if you can't and are unsure better to leave it out) add a blurb to the end of the PR description about what model and harness is making the changes
- Rebase onto latest default branch before opening.
- When the issue the PR solves has a milestone copy its field into the PR's milestone field.

## General
- Never use curl or similar to query GitHub API, always use the gh CLI
- Make sure all commits are GPG signed (you don't have to verify it after committing, Git is already configured). In case it times out stop and tell me to say continue to try it again
- When solving issues add a resolves #n to the commit message body. Only do it for the first matching commit when creating multiple commits (e.g. in a PR)
- Use pnpm if the project already uses it, otherwise use bun
  - Never use npm or yarn
- Always strive for concise, simple solutions. Channel "YAGNI" principles.
- If a problem can be solved in a simpler way, propose it
- Prefer CSS-only solutions over JS, if they have no downsides
- TypeScript: Never use `any` unless 100% necessary or specifically instructed
- Don't run dev server commands (e.g., `bun run dev`)
- Don't run build commands unless specficially told to
  - Exception: When you need to run a build to reproduce or verify tests it is allowed
- Focus on checking commands like `bun run typecheck`, `bun run lint`, etc.
- If you need to run anything as root, use pkexec or stop and ask the user to run everything you need to continue
- If something is not entirely clear to you, prefer asking a clarification question. Especially when there could be multiple ways to interpret the message (The user is a German native speaker)

## Info
The user uses KDE Plasma (Wayland) on Arch Linux. They prefer using privacy-respecting solutions. Respect that when choosing depenidencies (EXAMPLE: use Bunny Fonts instead of Google Fonts)

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
