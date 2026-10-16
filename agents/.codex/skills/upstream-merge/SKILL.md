---
name: upstream-merge
description: Merge upstream into a fork, preserve the sync PR's merged status, and summarize conflicts and relevant changes.
---

# Upstream merge

Fetch and merge the upstream branch specified by the user or repository
instructions, falling back to upstream's default branch. Preserve the existing
pull bot PR from `upstream-sync` so GitHub marks it merged. Validate the result,
then push directly to the target branch once. Summarize conflicts, how you
resolved them, relevant upstream changes, and validation results.

- Use the requested target branch, otherwise the sync PR's base or our default
  branch. Do not assume the current topic branch is the destination.
- Merge the sync PR's actual head, then any newer upstream commits. Preserve
  their ancestry rather than squashing, cherry-picking, or using an `ours`
  merge. Verify both heads are ancestors of the result and the PR is marked
  merged after pushing.
- Preserve intentional fork changes, apply necessary integration fixes, and
  run relevant checks on the combined result. Recheck the target and source
  heads before pushing; incorporate changes and revalidate if they moved.
- Invoking this skill includes the final push unless the user requests local
  work or an assessment. If validation or permissions block delivery, report
  the blocker. Do not force-push or create a replacement PR without approval.
