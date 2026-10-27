# Rules

## Git

### Guidelines

- Use semantic commit messages by default. When merging another branch, use Git's default commit message.
- When using GitHub Actions, verify the latest release and pin each action to its full commit SHA with a version comment, e.g. `uses: owner/action@<full-commit-sha> # v1.0.0`.
- Do not generate or upload separate checksum files (e.g. `SHA256SUMS`) for GitHub releases.
- Use the `leaving-pr-comments` skill whenever posting on GitHub on my behalf, including replies to review threads.
- Use the `file-pr` skill whenever creating a PR.
- Use the `babysit` skill whenever babysitting, watching, or monitoring a PR.
- When creating a GitHub repository, disable Projects and Wiki, and add relevant topics.

## General
- When interacting with Cloudflare, use the cf CLI unless the project has a Wrangler configuration file.
- Use the `unslop` skill when drafting or editing prose for public use (e.g., issue and PR descriptions, READMEs, documentation, websites), or when explicitly requested. Do not invoke it for commit messages, titles (issue, PR, release), one-line release-note entries, short UI strings and alt text, agent instruction files (e.g., `AGENTS.md`, `SKILL.md`), ordinary conversation messages, or before reaching the writing/editing step.
- Keep explanations, plans, findings, and summaries in the conversation thread. Do not create Markdown reports or other write-up files in my projects unless I explicitly ask for a file. Keep thread updates concise; update existing project documentation when the task requires it.
- In messages to me, write every GitHub reference as a Markdown link: issues, PRs, and discussions (`[#123](https://github.com/<owner>/<repo>/pull/123)`, using the right path for the type), commits (`` [`abc1234`](https://github.com/<owner>/<repo>/commit/<full-sha>) ``), and branches (`` [`name`](https://github.com/<owner>/<repo>/commits/<name>) ``). Get the owner and repo from the remote. Leave refs that only exist locally as code and say they are unpushed.
- Do not add build or release instructions to a repository's main README.
- When website access or browser automation fails through the preferred tool, retry with `agent-browser` before concluding that the page is unavailable.
- Never use curl or similar to query GitHub API, always use the gh CLI
- Make sure all commits are GPG signed (you don't have to verify it after committing, Git is already configured). In case it times out stop and tell me to say continue to try it again
- When solving issues add a resolves #n to the commit message body. Only do it for the first matching commit when creating multiple commits (e.g. in a PR)
- Use pnpm if the project already uses it, otherwise use bun
  - Never use npm or yarn
- When adding or updating package manager dependencies in any programming language, verify the latest stable release in the official package registry and use it. Update the relevant manifests and lockfiles.
- Always configure Dependabot in `.github/dependabot.yml` for GitHub Actions and every supported package manager ecosystem and dependency directory used by the project, with a recurring update schedule. Keep existing coverage when extending the configuration, and report any ecosystems Dependabot does not support.
- Always strive for concise, simple solutions. Channel "YAGNI" principles.
- If a problem can be solved in a simpler way, propose it
- Do not preserve compatibility with unmerged or unreleased code. Before adding a follow-up migration or bumping an API, capability, schema, or protocol version, verify that the previous form exists on the default branch or in a published release. If it exists only in current work or a local development database, update the original migration or protocol and keep its initial version. Do not add production compatibility code solely to preserve local development state; instead, tell the user exactly what they must reset, regenerate, migrate, or reconfigure, and whether that adjustment loses data. If release status is unclear, check or ask first.
- Prefer CSS-only solutions over JS, if they have no downsides
- TypeScript: Never use `any` unless 100% necessary or specifically instructed
- Don't run dev server commands (e.g., `bun run dev`)
- Don't run builds just to check that code compiles; use typecheck, lint, and tests. Build when tests, a reproduction, device or lab testing, or proof of a change needs the artifact.
- Focus on checking commands like `bun run typecheck`, `bun run lint`, etc.
- Ask when plausible interpretations would materially change the requested outcome, scope, or consequences, especially when my wording may be ambiguous. Resolve routine implementation details using repository conventions and context, and continue work that does not depend on the answer.

## Temporary files

- Agent launchers set `TMPDIR` to a disk-backed per-session directory because `/tmp` is a small tmpfs. Put scratch files in `$TMPDIR`; do not hardcode `/tmp`, `/var/tmp`, or `~/.cache/agent-tmp`.
- `$TMPDIR` is deleted after your session exits, so do not keep anything there that must outlive the session.
- Delete scratch files as soon as the step that needed them is done, especially large ones (downloads, clones, traces, browser profiles, build output). Do not leave cleanup to the end of the session.

## Info
The user uses KDE Plasma (Wayland) on Arch Linux. They prefer using privacy-respecting solutions. Respect that when choosing dependencies (EXAMPLE: use Bunny Fonts instead of Google Fonts)

## Command execution

- NEVER execute the `sleep` or `timeout` commands, including through scripts or command chains. This restriction applies only to commands the agent runs, not to code, scripts, or documentation it writes.

### Root commands executed by the agent

- Use `pkexec` only when you, the agent, are executing a command through a terminal/tool and that command requires root. This lets me enter my password in KDE's authentication dialog instead of an inaccessible or timing-out `sudo` prompt.
- This is an agent execution rule, not a requirement for the code you write. Do not add `pkexec` or a polkit dependency to scripts, installers, application code, CI, tests, documentation, or commands for users to copy and run because of this rule. Follow the project's normal privilege handling, such as `sudo`, unless I explicitly request otherwise.
- If a script must run as root, put `pkexec` in your tool invocation, for example `pkexec bash ./root-task.sh`. Do not embed it in the script or change the script's privilege handling just because you will execute it.
- If you cannot authenticate through `pkexec`, ask me to run the required command in my terminal using the project's normal method, such as `sudo`.

### Output and validation

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
