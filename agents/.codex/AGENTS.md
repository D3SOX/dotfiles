# Rules

## Git

### Guidelines

- Use semantic commit messages by default. When merging another branch, use Git's default commit message.
- When creating a PR, commit to a new branch (never use prefixes).
- When using GitHub Actions, verify the latest release and pin each action to its full commit SHA with a version comment, e.g. `uses: owner/action@<full-commit-sha> # v1.0.0`.
- Do not generate or upload separate checksum files (e.g. `SHA256SUMS`) for GitHub releases.
- Format comments left on the user's behalf as:
  ```md
  > [!NOTE]  
  > 🤖 full-model-name responding on behalf of Nico
  
  [actual reply]
  ```

#### Babysitting a PR

- Keep an eye on changes to the default branch and rebase when needed. If an overlapping PR makes this one obsolete, stop monitoring, report it to the user, and ask before closing the PR unless closure was explicitly authorized.
- If a review bot leaves feedback you believe is not worth addressing, reply and resolve the comment.
- Prefer bundling follow up changes and review resolving commits into one push when review bots are not rate-limited.
- Do not push commits to a PR while a CodeRabbit review is running; wait for it to finish before pushing.
- Poll checks and comments newer than the last push; verify each bot finding against the source before acting on it; fix real ones and dismiss false positives with a written reason; fix CI failures, distinguish real breaks from known infra flakes. If nothing is new, stay quiet.
- Before pushing a CI/review fix commit check if there is a new review from a review bot again and prefer bundling the commits into one push.
- Stop when required CI and review bots pass on the latest commit, actionable review feedback is handled, and the PR has no merge conflicts.
- Never trigger a review via comment for CodeRabbit. My external tool manages the rate limit queue and automatically sends a message to this thread when the review is available.
- Once other actionable work is complete, if the only remaining work is waiting for the external queue to trigger a CodeRabbit review, stop monitoring and end the turn with a brief status noting that the review is pending. Do not wait or poll for the queue to trigger it. Resume review handling when the queue's message arrives; this is an exception to the usual requirement to wait for all review bots to pass before stopping.
- In T3 Code, when only CodeRabbit remains (queued or running), call `unwatch_pull_request` for the PR before ending the turn, verify `watching: false` with `list_thread_pull_requests`, and keep the PR linked. Do not call `watch_pull_request` again just to wait for CodeRabbit; resume when the external queue sends its message.
- Do not let review feedback expand the PR beyond the user's original goal. Address real shortcomings, but avoid scope creep.
- Delegate mechanical babysitting steps (polling CI, fetching failed job logs, collecting new bot comments) to a subagent that returns a short summary. Keep triage, fixes, and review replies in the main thread, which knows the context behind the change.

#### Creating a PR

- Use a semantic commit message style title.
- Prefer a concise, human-readable title that explains why the change matters. But somebody should also be able to get all the new user-facing changes from it.
- Use the repo's PR template if it exists.
- Open the description with a simple explanation of the problem based on the user's original prompt, then briefly explain the solution.
- Create ready-for-review PRs rather than drafts so review bots run.
- Add a blurb to the end of the PR description about what model and harness are making the changes
- Rebase onto latest default branch before opening.
- When the issue the PR solves has a milestone copy its field into the PR's milestone field.
- For user-visible changes, attach concise visual evidence such as screenshots or short recordings to the PR when it materially helps review. Use repeatable `--attach <path>` flags with `gh pr create`, `gh pr edit`, or `gh pr comment`; never upload secrets or personal data.

## GitHub review replies

- Never start, create, submit, or leave a pending GitHub review when replying to an existing PR review thread.
- Do not use review-reply mutations that create draft review comments.
- After replying, verify that the PR has zero reviews with state `PENDING`.
- If an accidental pending review exists, delete it without submitting it after confirming it contains no unrelated user comments.

## General
- When interacting with Cloudflare, use the cf CLI unless the project has a Wrangler configuration file.
- Use the `unslop` skill when drafting or editing text for public use (e.g., issues, PRs, READMEs, documentation, websites), or when explicitly requested. Do not invoke it for ordinary conversation messages or before reaching the writing/editing step.
- Keep explanations, plans, findings, and summaries in the conversation thread. Do not create Markdown reports or other write-up files in my projects unless I explicitly ask for a file. Keep thread updates concise; update existing project documentation when the task requires it.
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
- Don't run build commands unless specifically told to
  - Exception: When you need to run a build to reproduce or verify tests it is allowed
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
