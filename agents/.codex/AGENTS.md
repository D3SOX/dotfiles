# Rules

## About me

I use KDE Plasma (Wayland) on Arch Linux. I prefer privacy-respecting solutions. Respect that when choosing dependencies and services. For example, self-host fonts instead of loading them from a third-party CDN, and if that isn't practical, use Bunny Fonts instead of Google Fonts.

I'm a German native speaker, so my English can be imprecise or read more than one way. Interpret it charitably and ask when the ambiguity matters.

## Approach

- Strive for concise, simple solutions (YAGNI). If a problem can be solved in a simpler way, propose it.
- Ask when plausible interpretations would materially change the requested outcome, scope, or consequences. Resolve routine implementation details using repository conventions and context, and continue work that does not depend on the answer.
- Fix small problems in the code you are changing, or with the same cause as the task, in the same change instead of offering a follow-up or a separate PR, and don't ask first. Report other bugs you find in your reply; open issues only when asked.
- After fixing a bug, check the same repo for the same bug in sibling code (other components, platforms, build variants, workflows) and fix what you can verify. Mention the rest, and other repos you know share the code, instead of touching them.
- Do not preserve compatibility with unmerged or unreleased code. Before adding a follow-up migration or bumping an API, schema, or protocol version, check that the previous form is on the default branch or in a release; if not, edit the original and keep its version. Instead of compatibility code for local development state, tell me what to reset, regenerate, or migrate, and whether that loses data. If release status is unclear, check or ask.

## Code

- Prefer modern CSS (`:has()`, container queries, `popover`, `<details>`, scroll-driven animations, anchor positioning) over JS for styling state, layout, and simple interactions, when the project's browser support allows it.
- Before showing me UI screenshots, check them for misalignment, uneven or empty space, wrapping, and horizontal scrolling, and fix what you find. In responsive layouts, prefer overflow menus or compact variants over wrapping rows or sideways scrolling.

## Communication

- When you need me to act or answer before you can continue (e.g., sign in, enter a device or pairing code, provide a password or token, confirm on a device, make a decision), ask with your question or secret tool, not in plain text. I don't see text from a running agent, so a plain-text request goes unnoticed. Put the link and code in the question itself. If a code expires before I answer, ask again the same way with a fresh one. Without such a tool, end your turn with the request.
- Keep explanations, plans, findings, and summaries in the conversation thread. Do not create Markdown reports or other write-up files in my projects unless I explicitly ask for a file. Keep thread updates concise; update existing project documentation when the task requires it.
- In messages to me, write every GitHub reference as a Markdown link: issues, PRs, and discussions (`[#123](https://github.com/<owner>/<repo>/pull/123)`, using the right path for the type), commits (`` [`abc1234`](https://github.com/<owner>/<repo>/commit/<full-sha>) ``), and branches (`` [`name`](https://github.com/<owner>/<repo>/commits/<name>) ``). Get the owner and repo from the remote. Leave refs that only exist locally as code and say they are unpushed.
- Ask me with your question tool before posting screenshots, recordings, or other captures that could show my personal data (from my physical devices, desktop, or signed-in accounts) anywhere public or external, such as PRs, issues, comments, or releases. Captures of emulators, VMs, or test accounts with only test data are fine.
- When drafting text for me to paste somewhere else (e.g., replies, comments, messages, emails, posts, descriptions), put the draft in a fenced code block labeled with the format the destination expects (e.g., `markdown` for GitHub or Reddit, `text` for plain-text fields), so I can copy the raw source. Keep commentary outside the block, and use a longer fence if the draft itself contains triple backticks.

## Writing and documentation

- Do not add build or release instructions to a repository's main README.

## Git

- Use semantic commit messages by default. When merging another branch, use Git's default commit message.
- Make sure all commits are GPG signed (you don't have to verify it after committing, Git is already configured). If signing times out, ask me with your question tool whether to retry, and retry when I confirm. Without a question tool, stop and tell me to say continue to retry.
- When solving issues with commits that are not part of a PR, add a resolves #n to the commit message body of the first matching commit. Do not add it to commits in a PR.

## Dependencies

- In my own and new projects, use pnpm if the project already uses it, otherwise use bun.
  - Never use npm or yarn there.
  - In other people's repos and forks of them, use the package manager their lockfile names, and never add a second lockfile.
- When adding or updating package manager dependencies in any programming language, verify the latest stable release in the official package registry and use it. Update the relevant manifests and lockfiles.

## Tools and services

- Use the gh CLI for GitHub and the glab CLI for GitLab, never curl or similar.
- When interacting with Cloudflare, use the cf CLI unless the project has a Wrangler configuration file.
- When website access or browser automation fails through the preferred tool, retry with `agent-browser` before concluding that the page is unavailable.

## Commands

### Validation

- Validate with checking commands like `bun run typecheck`, `bun run lint`, and tests. Don't run builds just to check that code compiles; build when tests, a reproduction, device or lab testing, or proof of a change needs the artifact.
- Don't run dev server commands (e.g., `bun run dev`).

### Shared machine

- Many agents run on this machine at once. Before heavy work (builds, emulators, VMs, test suites, or resuming or spawning several agents), check load and free memory. If load is above the core count or memory is tight, reduce workers or run heavy jobs one at a time.
- Only stop processes you started, by PID. Never pattern-kill shared tools (e.g. `pkill webpack`), since that can stop other sessions' work.

### Waiting

- Wait for the actual event, not for a guessed number of seconds. Block on the process or event itself (`wait`, a tool's own wait/watch flag, harness background-task notifications), or poll a concrete readiness check (status command, health endpoint, open port, file) in a bounded loop. Never use a fixed `sleep N` to mean "it's probably done by now".
- `sleep` is fine as the short interval inside such a poll loop or to keep a process alive (e.g. a lock holder). `timeout` is fine for bounding commands that may hang.
- After you push or merge to the default branch, or start a release or nightly, watch the runs it triggers until they finish. Fix failures your change caused and flaky tests, rerun what you can't fix, and report the rest, including runs that are stuck or awaiting approval. Don't move tags, delete releases, or publish drafts unasked. A release is done when its workflow has published it, not when the tag is pushed.

### Output filtering

- Use `rtk <cmd>` for noisy output (tests, builds, linters, logs, broad searches) when a summary suffices, and only on the chain segments that need it. Run raw when you need exact or complete output, or when rtk hides detail or rejects a flag.

## Files

- Agent launchers set `TMPDIR` to a disk-backed per-session directory that is deleted when the session exits. Put scratch files there, not in `/tmp` (a small tmpfs), `/var/tmp`, or `~/.cache/agent-tmp`, and nothing that must outlive the session.
- Screenshots, recordings, and other media you show or link in a message must outlive the session. Save or copy them to `~/Pictures/agent-captures/<project>/` (create it if needed), where `<project>` is the repository name from `git remote get-url origin` with the remote's casing (not the worktree or directory name). Do not use `$TMPDIR` or a directory that later test runs clear. A daily systemd-tmpfiles job deletes captures untouched for 3 days.
- Delete scratch files as soon as the step that needed them is done, especially large ones (downloads, clones, traces, browser profiles, build output). Do not leave cleanup to the end of the session.
