---
name: upstream-merge
description: Merge upstream into a fork through the pull bot's sync PR (or a new one), fix it, and take it to a merged PR with full-send.
---

# Upstream merge

Fetch the upstream branch specified by the user or repository instructions,
falling back to upstream's default branch. Never merge directly into the
target branch. Deliver the merge through a PR, then follow the `full-send`
skill to take it to a merged PR. Invoking this skill grants full-send's
autonomy unless the user requests local work or an assessment.

- Use the requested target branch, otherwise the sync PR's base or our default
  branch. Do not assume the current topic branch is the destination.
- If the pull bot has an open PR from `upstream-sync`, take it over: check out
  its head branch, merge any newer upstream commits, then merge the target
  branch if the PR conflicts with it. Push to that branch without force.
- If there is no sync PR, create `upstream-sync` from the target branch, merge
  upstream into it, push it, and open a PR with the `file-pr` skill.
- Preserve ancestry: use merges only, never rebase, squash, cherry-pick, or an
  `ours` merge. Preserve intentional fork changes and commit any integration
  fixes the combined result needs on the same branch.
- Then run `full-send` on the PR, with these exceptions:
  - When the branch falls behind, merge the target branch into it instead of
    rebasing.
  - Merge with a merge commit, whatever method the repo usually uses. If merge
    commits are disallowed, ask the user.
  - For the bot's PR, post the summary and proof line as a comment with the
    `leaving-pr-comments` skill instead of editing its description.
  - If the bot rewrites the branch while you work, redo the merge and fixes on
    its new head instead of force-pushing over it.
- Before merging, verify the upstream head is an ancestor of the PR head.
- In the final report, add the conflicts, how you resolved them, and the
  relevant upstream changes.
