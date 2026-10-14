---
name: dependabot
description: >-
  Validate all open Dependabot PRs in a repository, apply required migrations
  and fixes, and integrate them as one tested batch. Use when the user asks to
  clear, validate, or merge Dependabot updates.
---

# Dependabot

Combine the requested Dependabot updates, fix regressions caused by them, and
validate the complete batch before updating the default branch once. If the
user requested only an assessment, report findings without pushing or merging.
A request to merge the updates authorizes delivery within repository rules.

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
- Check branch protection, rulesets, and allowed merge methods before choosing
  delivery. Follow the repository's AGENTS.md and PR review rules. In T3 Code,
  link the PRs being handled and any batch PR to the thread when supported.

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
- When repository rules permit direct pushes, push the validated batch to the
  default branch with one normal fast-forward push using an explicit refspec,
  `git push origin HEAD:refs/heads/<default-branch>`. Never force-push or bypass
  protection. A rejected push changes nothing; inspect the reason before
  retrying, and revalidate if the default branch advanced.
- If rules require a PR, push the batch branch and open one ready-for-review
  PR listing the included updates, migration fixes, and validation. Satisfy its
  required checks and reviews, then merge it once with a merge commit and a
  check that its head still matches the validated SHA. Follow the repository's
  monitoring workflow if checks or reviews are still pending.
- If repository rules prohibit preserving ancestry, explain the conflict with
  the requested batch workflow and ask before switching to another strategy.
  Do not change repository protections or close the source PRs as a workaround.
- GitHub can mark source PRs merged when their head commits become reachable
  from the base branch. See [GitHub's indirect merge documentation](https://docs.github.com/en/pull-requests/reference/pull-request-merges#indirect-merges).
  Verify the delivered default-branch SHA and every included PR's merged state.
  If a PR is still open, investigate whether its head moved; do not close it
  merely because a similar version change was delivered.
- Check post-delivery CI when available and report any failure. Finish with a
  concise list of merged PRs, fixes, validation, and remaining blockers. When
  handing back work in T3 Code, stop watching the linked PRs as required.
