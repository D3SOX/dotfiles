---
name: sol-loop
description: Use when the user says "sol-loop" or "sol loop", or another skill or instruction tells you to run it.
---
# Sol Loop

Have GPT Sol review your changes in a loop, before or after opening a PR. You own the code; Sol only reviews it. Make the smallest changes that satisfy valid findings. Watch for scope creep, and push back when Sol is wrong.

## Budget

- 3 rounds. Round 1 reviews the full change. Later rounds review only what changed since the previous round, plus findings that are still open.
- Extend to 5 rounds only while a blocker or should finding stays open with evidence and involves security, permissions, auth, data loss, migrations, or state/concurrency. Also extend if the user asks.
- Stop early when Sol approves or a round returns only nits. Declined nits and comment-, doc-, or format-only fixes don't need another round.
- One reviewer at a time. Never run rounds in parallel, and never edit scoped files while a round is running, because Sol reads the same checkout.
- Don't push during the loop.

## Scope

Before round 1:

1. Run `git status --short`. Never stash, discard, or include unrelated changes. If the change can't be separated from unrelated work by paths, stop and ask.
2. Run `git fetch origin`, then find the base:
   - Open PR: `gh pr view <n> --json baseRefName,headRefOid`. Confirm `HEAD` is the PR head, or ahead of it only by this change. Base: `git merge-base HEAD origin/<baseRefName>`.
   - Local change: `git merge-base HEAD origin/<default-branch>`.
3. The change is the base to the working tree, plus untracked files, limited to the change's paths. Use the same diff command in every round.
4. Write down the intent and what's out of scope in one or two sentences each.
5. Run the checks that cover the change (typecheck, lint, tests). Don't send code that the change breaks. Note missing or already-failing checks in the brief.
6. Record `git diff --shortstat <base>` so you can compare the size at the end.

## Rules for findings

- Verify every finding and its severity against the source yourself. Another code path, a rare case, or a small cost is a nit, whatever label Sol gave it.
- Agree: make the smallest fix. Prefer deleting or narrowing code over adding a lock, cache, helper, or option. Fix the case that happened. Add one focused test that fails without the fix, but only if the intent needs it.
- Disagree: explain why, with evidence (file:line, a test, or output).
- Decline in one line: nits, style, extra docs or comments, speculative hardening, refactors of untouched code, and issues that predate the change. List them as follow-ups instead of fixing them.
- After each round of fixes, rerun the checks and `git diff --shortstat <base>`. If the reviews made the diff bigger, cut it back before the next round.
- Hold your position when you're right. A repeated finding doesn't become correct because it was repeated, and never agree just to end the loop.

## Calling Sol

Inside a T3 thread:

- Call `orchestrator_capabilities` and pick the newest Sol model on the `codex` provider, unless the user named a version. Don't hardcode an ID. Record the provider, model, and effort.
- Start each round with `delegate_task`: `role: "review"`, `isolation: "shared"`, `mode: "wait"`, `timeoutMs: 1800000`, `options: {"reasoningEffort": "high"}`. Use `xhigh` for rounds that review risky changes.
- Use a fresh `delegate_task` each round, with `clientRequestId` set to `sol-loop-<branch>-r<round>`. Keep that ID stable across retries of the same round. Carry context in the ledger instead of in Sol's previous conversation. Don't use `t3_thread_send`, `create_threads`, or `t3_thread_launch` for reviews.
- If the wait times out, keep the `taskId` and end the turn. The completion notification will wake you. Don't poll it or start a second reviewer.
- If `codex` fails because of usage limits, retry the round once on `codex_second`, but only if it lists a Sol model.

Outside T3, run the Codex CLI read-only. It uses the model from `~/.codex/config.toml`:

```sh
codex exec -s read-only -c model_reasoning_effort=high --ephemeral \
  -o "$TMPDIR/sol-r<round>.md" - < "$TMPDIR/sol-prompt-r<round>.md" 2> "$TMPDIR/sol-r<round>.log"
```

Run it in the background and wait for the completion notification. Take the model from the `model:` line in the log, then delete all three files once you've read the result.

Never substitute a model. If no route runs Sol, report the blocker. A timeout, an error, or a missing reply is never approval. If a round fails, cancel it, confirm that it stopped, and restart it with the ledger.

## Prompt

Every round's prompt must stand on its own, because Sol gets no history:

```
Review only. Do not edit, commit, push, comment on PRs, or start subagents.
Repo: <abs path>  Base: <sha>  PR: <n, if open>
Intent: <intent>  Out of scope: <scope>  Checks: <results>
Diff: git diff <base> [-- <paths>]; read untracked files from git status --short.
Read the surrounding code. Find bugs, broken callers, and mismatches with the intent.
Skip style unless it hides a bug. Hold the change to the smallest that meets the intent,
and flag code, tests, or guards the intent doesn't need.
Severity: blocker = the intended case is wrong. should = a real bug that callers will hit,
within the intent. nit = everything else, including other paths, rare cases, small
performance costs, and extra compatibility.
Reply with one finding per line, using stable IDs across rounds:
S1 [blocker|should|nit] <file>:<line> <claim>. Failure: <concrete scenario>. Fix: <suggestion>
End with exactly one line: VERDICT: APPROVE or VERDICT: CHANGES
```

From round 2 on, also send the ledger, the hunks you changed since the last round, and this instruction: "Review only the open IDs and the code changed since the last round. Mark each earlier ID `resolved` or `still open: <reason>`. Accept or contest each declined or disputed finding with a reason. Raise new findings elsewhere only if they're blockers."

Start another round only if budget remains and a blocker or should finding is open, behavior code changed, or Sol's approval doesn't cover the current behavior diff.

## Ledger

Keep a ledger in the thread, not in a file. Record one row per finding:

`S<n> | severity | file:line | summary | fixed / disagree: evidence / declined: reason / open`

After each round, post a short update in the thread: the round number, the verdict, and what you fixed, disputed, or declined.

## Finishing

The loop ends in one of two ways:

- **Agreed:** Sol approves the current behavior diff, no blocker or should finding is open, and you have no concerns of your own.
- **Stuck:** a finding is still disputed after two replies, or the budget ran out. Running out of budget is not approval. Give both sides in 2–3 lines each, and let the user decide.

Run the project's relevant checks on the final state, then report: the round count, the model and effort, Sol's last verdict, the diff size before and after, fixed findings, declined and disputed findings with their reasons, follow-ups, and whether anything was pushed. Never soften or omit Sol's verdict.

Push only if the user asked you to push, ship, or update the PR. When you create or update a PR afterwards, add this above the model and harness blurb at the end of the description:

```md
Reviewed with sol-loop: <n> rounds with <model> on <effort>.
Sol verdict: <approved | changes requested: one-line summary of what remains and why>
```
