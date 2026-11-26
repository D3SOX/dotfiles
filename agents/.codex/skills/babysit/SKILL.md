---
name: babysit
description: >-
  Keep a PR merge-ready by triaging comments, resolving clear conflicts, and
  fixing CI in a loop. Use when the user asks to babysit, watch, or monitor a PR.
---
# Babysit PR
Your job is to get this PR to a merge-ready state.

Check PR status, comments, and latest CI and resolve any issues until the PR is ready to merge.

1. Merge conflicts: Update the branch from its base only when it conflicts with the base or a required check needs the newer base. Follow the calling skill's rebase rules; without one, merge the base in instead of rebasing. Intelligently resolve any merge conflicts, preserving the intent and correctness of changes on your branch and the base branch. If intents conflict, abort the merge and ask for clarification. If an overlapping PR makes this one obsolete, stop monitoring, report it to the user, and ask before closing the PR unless closure was explicitly authorized.
2. Comments: Act on every thread whose last comment is not your reply, resolved or not, since bots reply to threads you already resolved. Read each comment body in full, except collapsed `<details>` blocks, and never cut it with `head` or `tail`; bots put the request between their analysis and their footer. Beyond the body, read only the minimum location/URL needed to act on it, not the entire JSON output or other unnecessary payload data. Verify each bot finding against the source before acting on it, and fix real ones. If feedback is not worth addressing, reply with a written reason. Use the `leaving-github-comments` skill for every reply.
   Every bot thread you answer ends resolved, including outdated threads: resolve a fixed thread after pushing the fix and replying with the commit, and a dismissed one right after the reply. Resolve in the same step as the reply (`pull_request_respond` with `resolved: true`, or the `resolveReviewThread` mutation outside T3 Code). Some bots such as CodeRabbit resolve their own threads, while others such as Codex never do, so don't take resolved threads as a sign that yours are done. Resolve a human reviewer's thread only after fixing what they asked; if you disagree, reply and leave it open. Leave a thread open when it needs the user's decision, and say so in your report.
3. CI: Fix CI failures, including flaky tests and failures unrelated to the change. Fix them in this PR unless the project's instructions send such fixes elsewhere, such as straight to the default branch. For a failure that seems unrelated, first check whether the branch is behind its base, since another PR may have fixed it. Rerun infrastructure failures you cannot fix. Never weaken CI checks or workflows just to make failures pass; report that case instead.

Stop when required CI and review bots pass on the latest commit, actionable review feedback is handled, every bot thread you answered is resolved, and the PR has no merge conflicts.

Rules:
- Before ending any turn, list the PR's unresolved review threads and resolve each bot thread whose last comment is your reply.
- On PRs in repos I don't maintain, only watch and report. Don't push, reply, or resolve threads there.
- Do not let review feedback expand the PR beyond the user's original goal. Address real shortcomings, but avoid scope creep.
- Bundle follow-up changes and review fixes into one push when review bots are not rate-limited. Before pushing, check for a new review from a review bot and include its fixes in the same push.
- Only the thread that owns the PR watches it. Delegated child tasks (Sol rounds, reviewers, any `delegate_task` child) never call `watch_pull_request`.
- Outside T3 Code, delegate mechanical steps (polling CI, fetching failed job logs, collecting new bot comments) to a subagent that returns a short summary. Keep triage, fixes, and review replies in the main thread, which knows the context behind the change.
- When an event needs no action, end the turn without a message. Never post or say "still waiting".
- If `gh pr view` or `gh pr checks` fails because the GraphQL rate limit is used up, use the separate REST limit: `gh api repos/<owner>/<repo>/pulls/<n>` for the PR and `gh api repos/<owner>/<repo>/commits/<sha>/check-runs` for checks.

CodeRabbit:
- Never trigger a CodeRabbit review via comment. The user's external tool manages the rate limit queue and automatically sends a message to this thread when the review is available.
- When the repository's "Wait for other bots" setting is on, that tool holds the PR while other bots' review threads are unresolved. An answered but unresolved thread then means CodeRabbit never reviews the PR, so waiting for its review alone never finishes.
- Do not push commits while a CodeRabbit review is running; wait for it to finish first.
