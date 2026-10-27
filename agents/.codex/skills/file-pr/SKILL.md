---
name: file-pr
description: Use when creating, filing, or opening a pull request.
---
# File PR

Before filing, check whether a PR for this branch already exists. Review the diff against the base branch to make sure its contents match the goal.

1. Branch: commit to a new branch without prefixes such as `feat/` or `codex/` (e.g. `fix-login-redirect`). Rebase onto the latest default branch before opening.
2. Title: use a semantic commit message style title. Prefer a concise, human-readable title that explains why the change matters, but somebody should also be able to get all the new user-facing changes from it.
3. Description: use the repo's PR template if it exists. Open with a simple explanation of the problem based on the user's original prompt, then briefly explain the solution. End with a blurb about the model and harness that made the changes. If `sol-loop` ran, put its line above that blurb.
4. Milestone: when the issue the PR solves has a milestone, copy it into the PR's milestone field.
5. Evidence: for user-visible changes, attach concise visual evidence such as screenshots or short recordings when it materially helps review. Use repeatable `--attach <path>` flags with `gh pr create`, `gh pr edit`, or `gh pr comment`.
6. Before submitting, check the title, description, and attachments for secrets and personal data.

Create ready-for-review PRs rather than drafts so review bots run. If the user also asked to babysit the PR, continue with the `babysit` skill.
