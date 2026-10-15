---
name: upstream-merge
description: >-
  Fetch and merge an upstream repository's default branch into a fork, preserve
  an existing upstream sync PR so it can be marked merged, push the validated
  result directly to the target branch once, and summarize conflicts and
  relevant changes. Use when the user asks to merge or sync upstream.
---

# Upstream merge

Merge the latest upstream default branch while preserving the fork's intended
changes and any existing sync PR's ancestry, then push the validated result
directly to the target branch once. Invoking `$upstream-merge` alone requests
this complete workflow and authorizes the final push using the authenticated
account's existing permissions. Honor an explicitly local merge or assessment
without publishing. Create a delivery PR only when the user explicitly
requests or approves one.

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
  In T3 Code, link the sync PR when supported.
- Inspect branch protection, rulesets, and the authenticated account's
  permissions, including existing admin or bypass allowances. A protected
  branch alone does not mean this account needs a PR.

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
- Push the validated result directly to the target branch with one normal
  fast-forward push using an explicit refspec,
  `git push origin HEAD:refs/heads/<target-branch>`. Existing admin or bypass
  permissions may allow GitHub to accept this push despite PR requirements.
  Never force-push, change protections, or grant additional permissions.
- If the push is rejected because the target branch advanced, incorporate the
  new target state while preserving the merged heads, repeat affected
  validation, and retry. For a permissions or policy rejection, report the
  exact blocker and leave the merge local. Do not push a delivery branch or
  create a PR without the user's explicit authorization.
- If the user explicitly chooses a delivery PR instead, open one ready-for-review
  PR, link it to the thread, and follow repository checks and review rules.
  Preserve ancestry when merging and verify its head still matches the
  validated SHA.
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
