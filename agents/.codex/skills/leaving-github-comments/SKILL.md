---
name: leaving-github-comments
description: Use before drafting or posting any GitHub comment on the user's behalf, on issues, PRs, discussions, or review threads, including comments posted while closing, reviewing, or resolving (e.g. `gh issue close --comment`, `gh pr review --body`).
---

# Leaving GitHub Comments

Prefix every agent-authored comment left on the user's behalf with this GitHub
note callout:

```md
> [!NOTE]  
> 🤖 full-model-name responding on behalf of Nico

Actual comment starts here.
```

Keep the two trailing spaces after `[!NOTE]`. Use the public model name the
harness reports for the model that wrote the comment. If the harness does not
expose a model name, use the harness name. Do not guess.

Before posting, check the entire comment, including quoted text and
attachments, for secrets and private details.

Keep the attribution inside the note and the actual reply outside it. Do not
add a horizontal rule, Setext underline, heading, signature footer, or a second
attribution.

Add the note already in drafts you show the user before posting, so the
approved text is what gets posted.

Apply this format to top-level PR and issue comments, inline review comments,
replies to bots or reviewers, and written explanations used before resolving or
dismissing feedback. Do not add it to PR descriptions, issue bodies when
creating issues, commit messages, or text the user explicitly asked to post
verbatim without attribution.

Write the comment itself in a direct style:

- Lead with the conclusion.
- Cite the relevant code, behavior, check, or reproduction.
- Keep it concise and avoid filler, canned thanks, or status narration.
- Distinguish verified facts from judgment.

Preview the final Markdown before posting so quoting and blank lines render as
shown. After posting, verify that GitHub returned the comment or review URL.
Resolve a review thread only after its response was posted successfully.

## Replying to review threads

- Never start, create, submit, or leave a pending GitHub review when replying
  to an existing PR review thread.
- Do not use review-reply mutations that create draft review comments.
- After replying, verify that the PR has zero reviews with state `PENDING`.
- If an accidental pending review exists, delete it without submitting it after
  confirming it contains no unrelated user comments.
