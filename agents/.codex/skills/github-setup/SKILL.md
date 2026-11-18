---
name: github-setup
description: Use when creating a GitHub repository, adding or editing GitHub Actions workflows, configuring Dependabot, or publishing GitHub releases. Also use when changing CI or dependencies in a repo without `.github/dependabot.yml`.
---

# GitHub setup

- New repositories: disable Projects and Wiki, add relevant topics, and watch the repo for all activity on my account (`gh api -X PUT repos/<owner>/<repo>/subscription -F subscribed=true`).
- Actions: verify the latest release and pin each action to its full commit SHA with a version comment, e.g. `uses: owner/action@<full-commit-sha> # v1.0.0`.
- Releases: do not generate or upload separate checksum files (e.g. `SHA256SUMS`).
- Dependabot: configure `.github/dependabot.yml` for GitHub Actions and every supported package ecosystem and dependency directory the project uses, with a recurring schedule. Keep existing coverage when extending it, and report ecosystems Dependabot does not support.
- Also find dependencies Dependabot cannot track, such as versions pinned in scripts, download URLs, build args, or source constants. If there are any, list them and ask with your question tool whether to add a scheduled GitHub Actions workflow that opens PRs to update them. Without a question tool, ask in your reply.
