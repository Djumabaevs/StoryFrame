# CLAUDE.md

Project notes for Claude Code sessions on this repo.

## Daily sync routine

When asked to make a daily commit / daily sync / daily update:

1. Work on branch `claude/dreamy-pasteur-8sxaq` (or a fresh `claude/*` branch if the old one was already merged).
2. Make 2–4 small commits touching the daily log files (`DAILY_LOG.md`, `CHANGELOG.md`, `.activity_log.md`, `.last_updated`, etc.).
3. Push the branch with `git push -u origin <branch>`.
4. Open a PR targeting `main` using the GitHub MCP tools.
5. Call `enable_pr_auto_merge` with `mergeMethod: SQUASH` so the PR auto-merges once checks pass.
   - If the PR is already in clean status, merge directly via `merge_pull_request` (squash). Auto-merge only applies while checks are pending.
6. Confirm with the user before the final merge action (per the "always confirm" preference) unless the user has pre-authorized that session.

The `.github/workflows/auto-merge-daily.yml` workflow also enables auto-merge automatically for any PR from a `claude/*` branch, so step 5 is belt-and-suspenders.

## Branching

- Never force-push. If a `claude/*` branch diverges after a squash merge, cut a new branch from `origin/main` instead.
- Always push to the `claude/*` branch; `main` is updated only via merged PRs.
