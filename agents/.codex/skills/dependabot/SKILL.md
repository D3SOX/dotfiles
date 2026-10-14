---
name: dependabot
description: >-
  Validate all open Dependabot PRs in a repository, apply required migrations
  and fixes, and push the tested batch directly to the default branch once.
  Use when the user asks to clear, validate, or merge Dependabot updates.
---

# Dependabot

Combine the requested Dependabot updates, fix regressions caused by them, and
validate the complete batch, then push it directly to the default branch once.
Invoking `$dependabot` alone requests this complete workflow and authorizes the
final push using the authenticated account's existing permissions. If the user
requested only an assessment, report findings without pushing or merging.
Create a batch PR only when the user explicitly requests or approves one.

## Collect the updates

- Use `gh` to discover the repository and its actual default branch. List open
  PRs with `gh pr list --state open --app dependabot --limit 1000` and request
  only the JSON fields needed for the task. If the limit is reached, paginate
  with `gh api` so no PRs are missed.
- Record each PR's URL, base branch, head SHA, and dependency changes. Include
  grouped and security updates. Report PRs targeting other branches separately;
  do not retarget them into the default branch batch.
- Read each diff, relevant release notes and migration guides, CI results, and
  unresolved review feedback. Check for overlapping updates and incompatible
  versions, including peer dependencies and runtime requirements.
- Read repository instructions and inspect branch protection, rulesets, and the
  authenticated account's permissions, including existing admin or bypass
  allowances. A protected branch alone does not mean this account needs a PR.
  In T3 Code, link the source PRs being handled to the thread when supported.

## Assemble and validate

- Start a new branch without a prefix in an isolated worktree from the latest
  remote default branch. Preserve the user's uncommitted work.
- Fetch each recorded PR head and verify its SHA. Merge the heads locally with
  signed merge commits and Git's default merge messages, preserving their
  ancestry. Do not squash or cherry-pick the updates. Choose an order that
  accounts for related dependencies and resolve conflicts using the intended
  final versions. Do not silently discard an update during conflict resolution.
- Apply necessary API migrations, configuration changes, and fixes in the
  batch. Regenerate conflicting lockfiles with the project's package manager.
  Keep fixes limited to the updates and use signed semantic commits. Do not
  push intermediate fixes to the Dependabot branches.
- Install dependencies using the final lockfiles and run the relevant tests,
  type checks, lint checks, and targeted behavior checks. Run a build only when
  repository instructions allow it or it is needed to verify the updates.
  Validate the combined state even when individual PR checks pass.
- For failures, read the complete error and distinguish update regressions from
  existing failures by checking the default branch when needed. Fix regressions
  and rerun affected checks. Do not weaken tests or CI to make the batch pass.
- If an update cannot be fixed or meaningfully validated, report the blocker
  and leave the batch unmerged. Do not deliver only a subset unless the user
  authorizes it. State verification limits without claiming nothing can break.

## Deliver once

- Before delivery, fetch the default branch again and recheck the included
  PRs' states and head SHAs. If the base or a head changed, incorporate the new
  state and repeat affected validation. Report newly opened PRs separately
  rather than continually expanding the initial batch.
- Push the validated batch directly to the default branch with one normal
  fast-forward push using an explicit refspec,
  `git push origin HEAD:refs/heads/<default-branch>`. Existing admin or bypass
  permissions may allow GitHub to accept this push despite PR requirements.
  Never force-push, change protections, or grant additional permissions.
- If the push is rejected because the default branch advanced, incorporate the
  new base, repeat affected validation, and retry. For a permissions or policy
  rejection, report the exact blocker and leave the batch local. Do not push a
  batch branch or create a PR without the user's explicit authorization.
- If the user explicitly chooses a batch PR instead, open one ready-for-review
  PR, link it to the thread, and follow repository checks and review rules.
  Preserve ancestry when merging and verify its head still matches the
  validated SHA. If ancestry cannot be preserved, report the conflict before
  switching strategies. Do not close the source PRs as a workaround.
- GitHub can mark source PRs merged when their head commits become reachable
  from the base branch. See [GitHub's indirect merge documentation](https://docs.github.com/en/pull-requests/reference/pull-request-merges#indirect-merges).
  Verify the delivered default-branch SHA and every included PR's merged state.
  If a PR is still open, investigate whether its head moved; do not close it
  merely because a similar version change was delivered.
- Check post-delivery CI when available and report any failure. Finish with a
  concise list of merged PRs, fixes, validation, and remaining blockers. When
  handing back work in T3 Code, stop watching the linked PRs as required.
