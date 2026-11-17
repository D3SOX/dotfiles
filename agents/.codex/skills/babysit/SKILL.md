---
name: babysit
description: >-
  Keep a PR merge-ready by triaging comments, resolving clear conflicts, and
  fixing CI in a loop. Use when the user asks to babysit, watch, or monitor a PR.
---
# Babysit PR
Your job is to get this PR to a merge-ready state.

Check PR status, comments, and latest CI and resolve any issues until the PR is ready to merge.

1. Merge conflicts: Keep an eye on changes to the default branch and rebase when needed. Intelligently resolve any merge conflicts, preserving the intent and correctness of changes on your branch and the base branch. If intents conflict, abort the merge and ask for clarification. If an overlapping PR makes this one obsolete, stop monitoring, report it to the user, and ask before closing the PR unless closure was explicitly authorized.
2. Comments: Only act on comments newer than the last push. Filter out resolved threads first. Read only each comment body and the minimum location/URL needed to act on it; do not read the entire JSON output or other unnecessary payload data. Verify each bot finding against the source before acting on it, and fix real ones. If feedback is not worth addressing, reply with a written reason. Use the `leaving-pr-comments` skill for every reply.
   Every thread you answer ends resolved, from any reviewer bot and including outdated threads: resolve a fixed thread after pushing the fix and replying with the commit, and a dismissed one right after the reply. Leave a thread open only when it needs the user's decision, and say so in your report.
3. CI: Fix CI failures caused by changes within this PR's scope, and distinguish real breaks from known infra flakes. Never change CI checks/workflows just to make failures pass, or make unrelated code changes; if that would be required, report back instead. For merge-blocking failures that seem unrelated to this PR, check whether the branch is behind the base branch and merge latest changes, since another PR may have fixed them.

Stop when required CI and review bots pass on the latest commit, actionable review feedback is handled, every review thread you answered is resolved, and the PR has no merge conflicts.

Rules:
- Before ending any turn, list the PR's unresolved review threads and resolve each one whose last comment is your reply.
- Do not let review feedback expand the PR beyond the user's original goal. Address real shortcomings, but avoid scope creep.
- Bundle follow-up changes and review fixes into one push when review bots are not rate-limited. Before pushing, check for a new review from a review bot and include its fixes in the same push.
- Only the thread that owns the PR watches it. Delegated child tasks (Sol rounds, reviewers, any `delegate_task` child) never call `watch_pull_request`.
- Delegate mechanical steps (polling CI, fetching failed job logs, collecting new bot comments) to a subagent that returns a short summary. Keep triage, fixes, and review replies in the main thread, which knows the context behind the change.
- When an event needs no action, end the turn without a message. Never post or say "still waiting".
- If `gh pr view` or `gh pr checks` fails because the GraphQL rate limit is used up, use the separate REST limit: `gh api repos/<owner>/<repo>/pulls/<n>` for the PR and `gh api repos/<owner>/<repo>/commits/<sha>/check-runs` for checks.

CodeRabbit:
- Never trigger a CodeRabbit review via comment. The user's external tool manages the rate limit queue and automatically sends a message to this thread when the review is available.
- When the repository's "Wait for other bots" setting is on, that tool holds the PR while other bots' review threads are unresolved. An answered but unresolved thread then means CodeRabbit never reviews the PR, so waiting for its review alone never finishes.
- Do not push commits while a CodeRabbit review is running; wait for it to finish first.
