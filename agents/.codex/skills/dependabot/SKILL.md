---
name: dependabot
description: Validate and fix open Dependabot updates, then merge them together in one push to the default branch.
---

# Dependabot

Find all open Dependabot PRs. Check for breaking changes, apply any required
migrations or fixes, and merge the validated batch into the default branch
with one push.

- Start from the latest remote default branch and merge the PR heads locally,
  preserving ancestry so GitHub marks the PRs merged. Report PRs targeting
  other branches separately.
- Read the diffs and relevant migration guidance. Resolve overlapping updates
  and lockfile conflicts, then run relevant checks on the combined result,
  even when individual PR checks pass. Keep fixes scoped to the updates.
- Recheck the default branch and included PR heads before pushing. Incorporate
  changes and repeat affected validation if they moved.
- Invoking this skill includes the final push unless the user requests an
  assessment. If an update cannot be fixed or validated, or permissions block
  delivery, report the blocker. Do not silently merge a subset, force-push,
  or create a batch PR without approval.
- Verify the remote result and each PR's merged status. Summarize merged
  updates, migrations or fixes, validation results, and any blockers.
