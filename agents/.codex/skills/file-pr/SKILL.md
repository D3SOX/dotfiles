---
name: file-pr
description: Use when creating, filing, or opening a pull request.
---
# File PR

Before filing, check whether a PR for this branch already exists. In a fork, open the PR against the fork (`--repo` with the `origin` repo) unless I asked for an upstream PR. Review the diff against the base branch to make sure its contents match the goal.

1. Branch: name the branch after the change's final scope, without prefixes such as `feat/` or `codex/` (e.g. `fix-login-redirect`). Create or rename a branch when the current name doesn't fit, unless the calling skill chose it. Before opening, rebase an unpushed branch onto the latest default branch, unless the calling skill forbids rebasing.
2. Title: use a semantic commit message style title. Prefer a concise, human-readable title that explains why the change matters, but somebody should also be able to get all the new user-facing changes from it.
3. Description: use the repo's PR template if it exists. Open with a simple explanation of the problem based on the user's original prompt, then briefly explain the solution. When the PR solves issues, add a `Resolves #n` line for each. End with a blurb about the model and harness that made the changes. If `sol-loop` ran, put its line above that blurb.
4. Milestone: unless the repo's instructions set other milestone rules, when the issue the PR solves has a milestone, copy it into the PR's milestone field.
5. Evidence: for user-visible changes, attach concise visual evidence such as screenshots or short recordings when it materially helps review. Use repeatable `--attach <path>` flags with `gh pr create`, `gh pr edit`, or `gh pr comment`.
6. Before submitting, check the title, description, and attachments for secrets and personal data.

Create ready-for-review PRs rather than drafts so review bots run. If the user also asked to babysit the PR, continue with the `babysit` skill.
