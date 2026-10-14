---
name: upstream-merge
description: >-
  Fetch and merge an upstream repository's default branch into a fork, preserve
  an existing upstream sync PR so it can be marked merged, and summarize
  conflicts and relevant changes. Use when the user asks to merge or sync upstream.
---

# Upstream merge

Merge the latest upstream default branch while preserving the fork's intended
changes and any existing sync PR's ancestry. Honor the requested destination
and delivery. A request to have the sync PR marked merged includes publishing
the result within repository rules. Keep an explicitly local merge local.

## Identify the source and sync PR

- Read repository instructions, Git remotes, and upstream sync workflows in
  `.github/workflows`. Use `gh` for GitHub queries. Determine the upstream
  repository from the configured remote, fork parent, and workflow source.
  Discover its actual default branch rather than assuming `main` or `master`.
  Ask if these sources identify different upstream repositories.
- Use the user's target branch when specified. Otherwise use the existing sync
  PR's base branch, or the fork's default branch if there is no sync PR. Do not
  assume the current topic branch is the intended destination.
- Inspect open PRs for the workflow's configured branch and author. Treat
  `upstream-sync` and a pull bot as hints, not fixed names. Verify the source,
  base branch, and diff before selecting a PR. Ask if multiple PRs are plausible
  or the workflow targets a different source branch than the requested upstream
  default branch. Do not create or run a workflow just to produce a sync PR.
- Record the target SHA, upstream default-branch SHA, and any sync PR URL and
  head SHA. Read its checks and unresolved feedback. Inspect extra bot changes;
  do not import unrelated changes merely to make a PR appear merged.
  In T3 Code, link the sync PR and any delivery PR when supported.

## Merge and validate

- Fetch the upstream default branch, target branch, and selected PR head.
  Verify fetched PR commits match the recorded head SHA. Use an isolated
  worktree and a new branch without a prefix when preparing remote delivery;
  preserve the user's uncommitted work.
- If a sync PR exists, merge its exact head with a signed merge commit and
  Git's default merge message. Then merge the fetched upstream default branch
  if it contains additional commits. This handles a stale sync PR while keeping
  both histories reachable. Without a sync PR, merge upstream directly.
- Preserve ancestry. Do not squash, cherry-pick, rebase away the bot commits,
  or use an `ours` merge to claim integration without incorporating changes.
  Verify both the recorded bot head and upstream head are ancestors of the
  result with `git merge-base --is-ancestor` when applicable.
- Resolve conflicts using the fork's intended behavior and upstream changes.
  Inspect each conflict rather than choosing one side for every file. Preserve
  intentional fork settings and regenerate conflicting lockfiles using the
  project's package manager. Keep a concise record of conflicted files and
  the decisions made. Ask when incompatible product choices cannot be inferred.
- Apply migrations or fixes required by the merge, limiting changes to the
  integration. Sign commits you create and use semantic messages for fix
  commits. If signing times out, stop and ask the user to say continue.
- Run relevant tests, type checks, lint checks, and targeted behavior checks
  on the merged state. Follow repository restrictions on builds and dev servers.
  Investigate failures against the pre-merge target when needed, fix merge
  regressions, and report remaining failures or verification limits.

## Deliver and summarize

- Before publishing, recheck the target, upstream default branch, and sync PR
  head. Incorporate changes and repeat affected validation if they moved.
  If upstream is already integrated, check whether the bot head still needs
  merging before reporting that there is nothing to do.
- Deliver the validated result with a normal fast-forward push when authorized
  and permitted. If protection requires a PR, open one ready-for-review PR and
  follow repository checks and review requirements before merging it with a
  merge commit. Match the PR head to the validated SHA. Never force-push or
  bypass protections. If a push is rejected, inspect why before retrying.
- If repository rules prevent preserving ancestry, explain the conflict and
  ask before changing strategy. Do not close the bot PR as a substitute.
  GitHub's [indirect merge behavior](https://docs.github.com/en/pull-requests/reference/pull-request-merges#indirect-merges)
  depends on its head commits becoming reachable from the base branch.
- Verify the remote target contains the merged heads and the sync PR is marked
  merged after delivery. If it remains open, check whether the bot updated its
  head instead of assuming delivery completed the PR. Check post-delivery CI
  when available and report failures. Stop watching linked PRs when handing
  work back in T3 Code, as required by repository instructions.
- Summarize the result in the conversation. Compare the pre-merge target with
  the final result and explain relevant new behavior, fixes, dependency changes,
  and required user actions. List conflicts and how they were resolved, or state
  that there were none. Include validation, delivery status, the sync PR's state,
  and any blockers. Do not create a separate report file unless requested.
