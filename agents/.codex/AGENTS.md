# Rules

## About me

The user uses KDE Plasma (Wayland) on Arch Linux. They prefer using privacy-respecting solutions. Respect that when choosing dependencies and services (EXAMPLE: use Bunny Fonts instead of Google Fonts).

## Approach

- Always strive for concise, simple solutions. Channel "YAGNI" principles.
- If a problem can be solved in a simpler way, propose it.
- Ask when plausible interpretations would materially change the requested outcome, scope, or consequences, especially when my wording may be ambiguous. Resolve routine implementation details using repository conventions and context, and continue work that does not depend on the answer.
- Do not preserve compatibility with unmerged or unreleased code. Before adding a follow-up migration or bumping an API, capability, schema, or protocol version, verify that the previous form exists on the default branch or in a published release. If it exists only in current work or a local development database, update the original migration or protocol and keep its initial version. Do not add production compatibility code solely to preserve local development state; instead, tell the user exactly what they must reset, regenerate, migrate, or reconfigure, and whether that adjustment loses data. If release status is unclear, check or ask first.

## Code

- Prefer CSS-only solutions over JS, if they have no downsides.
- TypeScript: Never use `any` unless 100% necessary or specifically instructed.
- Before showing me UI screenshots, check them for misalignment, uneven or empty space, wrapping, and horizontal scrolling, and fix what you find. In responsive layouts, prefer overflow menus or compact variants over wrapping rows or sideways scrolling.

## Communication

- Keep explanations, plans, findings, and summaries in the conversation thread. Do not create Markdown reports or other write-up files in my projects unless I explicitly ask for a file. Keep thread updates concise; update existing project documentation when the task requires it.
- In messages to me, write every GitHub reference as a Markdown link: issues, PRs, and discussions (`[#123](https://github.com/<owner>/<repo>/pull/123)`, using the right path for the type), commits (`` [`abc1234`](https://github.com/<owner>/<repo>/commit/<full-sha>) ``), and branches (`` [`name`](https://github.com/<owner>/<repo>/commits/<name>) ``). Get the owner and repo from the remote. Leave refs that only exist locally as code and say they are unpushed.
- When drafting text for me to paste somewhere else (e.g., replies, comments, messages, emails, posts, descriptions), put the draft in a fenced code block labeled with the format the destination expects (e.g., `markdown` for GitHub or Reddit, `text` for plain-text fields), so I can copy the raw source. Keep commentary outside the block, and use a longer fence if the draft itself contains triple backticks.

## Writing and documentation

- Use the `unslop` skill when drafting or editing prose for public use (e.g., issue and PR descriptions, READMEs, documentation, websites), or when explicitly requested. Do not invoke it for commit messages, titles (issue, PR, release), one-line release-note entries, short UI strings and alt text, agent instruction files (e.g., `AGENTS.md`, `SKILL.md`), ordinary conversation messages, or before reaching the writing/editing step.
- Do not add build or release instructions to a repository's main README.

## Git

- Use semantic commit messages by default. When merging another branch, use Git's default commit message.
- Make sure all commits are GPG signed (you don't have to verify it after committing, Git is already configured). If signing times out, ask me with your question tool whether to retry, and retry when I confirm. Without a question tool, stop and tell me to say continue to retry.
- When solving issues with commits that are not part of a PR, add a resolves #n to the commit message body of the first matching commit. Do not add it to commits in a PR.

## GitHub

- Never use curl or similar to query GitHub API, always use the gh CLI.
- Use the `file-pr` skill whenever creating a PR.
- Use the `leaving-pr-comments` skill whenever posting on GitHub on my behalf, including replies to review threads.
- Use the `babysit` skill whenever babysitting, watching, or monitoring a PR.
- When creating a GitHub repository, disable Projects and Wiki, and add relevant topics.
- When using GitHub Actions, verify the latest release and pin each action to its full commit SHA with a version comment, e.g. `uses: owner/action@<full-commit-sha> # v1.0.0`.
- Do not generate or upload separate checksum files (e.g. `SHA256SUMS`) for GitHub releases.

## Dependencies

- Use pnpm if the project already uses it, otherwise use bun.
  - Never use npm or yarn.
- When adding or updating package manager dependencies in any programming language, verify the latest stable release in the official package registry and use it. Update the relevant manifests and lockfiles.
- Always configure Dependabot in `.github/dependabot.yml` for GitHub Actions and every supported package manager ecosystem and dependency directory used by the project, with a recurring update schedule. Keep existing coverage when extending the configuration, and report any ecosystems Dependabot does not support.
  - Also find dependencies Dependabot cannot track, such as versions pinned in scripts, download URLs, build args, or source constants. If there are any, list them and use your question tool to ask whether to implement a scheduled GitHub Actions workflow that opens PRs to update them. Without a question tool, ask in your reply.

## Tools and services

- When interacting with GitLab, use the glab CLI instead of curl or similar.
- When interacting with Cloudflare, use the cf CLI unless the project has a Wrangler configuration file.
- When website access or browser automation fails through the preferred tool, retry with `agent-browser` before concluding that the page is unavailable.

## Commands

### Validation

- Prefer running code, tests, linters, and type checks over guessing.
- Validate with checking commands like `bun run typecheck`, `bun run lint`, and tests. Don't run builds just to check that code compiles; build when tests, a reproduction, device or lab testing, or proof of a change needs the artifact.
- Don't run dev server commands (e.g., `bun run dev`).
- Read complete errors, logs, and stack traces before fixing them.

### Shared machine

- Many agents run on this machine at once. Before heavy work (builds, emulators, VMs, test suites, or resuming or spawning several agents), check load and free memory. If load is above the core count or memory is tight, reduce workers or run heavy jobs one at a time.
- Only stop processes you started, by PID. Never pattern-kill shared tools (e.g. `pkill webpack`), since that can stop other sessions' work.

### Waiting

- Wait for the actual event, not for a guessed number of seconds. Block on the process or event itself (`wait`, a tool's own wait/watch flag, harness background-task notifications), or poll a concrete readiness check (status command, health endpoint, open port, file) in a bounded loop. Never use a fixed `sleep N` to mean "it's probably done by now".
- `sleep` is fine as the short interval inside such a poll loop or to keep a process alive (e.g. a lock holder). `timeout` is fine for bounding commands that may hang.

### Output filtering

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

## Files

- Agent launchers set `TMPDIR` to a disk-backed per-session directory because `/tmp` is a small tmpfs. Put scratch files in `$TMPDIR`; do not hardcode `/tmp`, `/var/tmp`, or `~/.cache/agent-tmp`.
- `$TMPDIR` is deleted after your session exits, so do not keep anything there that must outlive the session.
- Screenshots, recordings, and other media you show or link in a message must outlive the session. Save or copy them to `~/Pictures/agent-captures/<project>/` (create it if needed), where `<project>` is the repository name from `git remote get-url origin` with the remote's casing (not the worktree or directory name). Do not use `$TMPDIR` or a directory that later test runs clear. A daily systemd-tmpfiles job deletes captures untouched for 3 days.
- Delete scratch files as soon as the step that needed them is done, especially large ones (downloads, clones, traces, browser profiles, build output). Do not leave cleanup to the end of the session.
