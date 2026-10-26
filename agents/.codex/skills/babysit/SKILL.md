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
2. Comments: Only act on comments newer than the last push. Filter out resolved threads first. Read only each comment body and the minimum location/URL needed to act on it; do not read the entire JSON output or other unnecessary payload data. Verify each bot finding against the source before acting on it, and fix real ones. If feedback is not worth addressing, reply with a written reason and resolve the comment. Use the `leaving-pr-comments` skill for every reply.
3. CI: Fix CI failures caused by changes within this PR's scope, and distinguish real breaks from known infra flakes. Never change CI checks/workflows just to make failures pass, or make unrelated code changes; if that would be required, report back instead. For merge-blocking failures that seem unrelated to this PR, check whether the branch is behind the base branch and merge latest changes, since another PR may have fixed them.

Stop when required CI and review bots pass on the latest commit, actionable review feedback is handled, and the PR has no merge conflicts.

Rules:
- Do not let review feedback expand the PR beyond the user's original goal. Address real shortcomings, but avoid scope creep.
- Bundle follow-up changes and review fixes into one push when review bots are not rate-limited. Before pushing, check for a new review from a review bot and include its fixes in the same push.
- Only the thread that owns the PR watches it. Delegated child tasks (Sol rounds, reviewers, any `delegate_task` child) never call `watch_pull_request`.
- Delegate mechanical steps (polling CI, fetching failed job logs, collecting new bot comments) to a subagent that returns a short summary. Keep triage, fixes, and review replies in the main thread, which knows the context behind the change.
- When an event needs no action, end the turn without a message. Never post or say "still waiting".
- If `gh pr view` or `gh pr checks` fails because the GraphQL rate limit is used up, use the separate REST limit: `gh api repos/<owner>/<repo>/pulls/<n>` for the PR and `gh api repos/<owner>/<repo>/commits/<sha>/check-runs` for checks.

CodeRabbit:
- Never trigger a CodeRabbit review via comment. The user's external tool manages the rate limit queue and automatically sends a message to this thread when the review is available.
- Do not push commits while a CodeRabbit review is running; wait for it to finish first.
- Once other actionable work is complete, if the only remaining work is waiting for the external queue to trigger a CodeRabbit review, stop monitoring and end the turn with a brief status noting that the review is pending. Do not wait or poll for the queue. Resume review handling when the queue's message arrives; this is an exception to the stop condition above.
- In T3 Code, when only CodeRabbit remains (queued or running), call `unwatch_pull_request` for the PR before ending the turn, verify `watching: false` with `list_thread_pull_requests`, and keep the PR linked. Do not call `watch_pull_request` again just to wait for CodeRabbit.
