---
description: Squash-merge an explicitly approved PR and clean up its worktree and branch
argument-hint: "[PR-number | PR-URL | branch]"
---

The user is explicitly authorizing a pull request merge. Complete the approved pull request merge workflow end to end.

The optional command argument is `${ARGUMENTS:-not provided}`. If an argument is provided, treat it as the target PR number, URL, or branch. If no argument is provided, use the most recently worked-on pull request identifiable from the conversation context, even when the current checkout is on another branch. If the conversation does not identify exactly one recent working pull request, ask the user to specify it rather than guessing.

1. Resolve the selected target with `gh pr view`. Read its number, title, body, URL, state, draft status, mergeability, merge-state status, base branch, head branch, head repository, head OID, and checks. Record the reviewed head OID before doing anything else.
2. Stop without merging if the pull request is closed, already merged, a draft, conflicted, missing approval required by repository policy, or has failed checks. Wait for pending required checks by polling every 30 seconds for up to 40 minutes; stop and report if the timeout expires. Never use `--admin` or otherwise bypass branch protection.
3. Re-read the pull request immediately before merging and ensure its head OID still matches the recorded OID.
4. Use `gh api` to read the base repository's merge settings and verify that `squash_merge_commit_title` is `PR_TITLE` and `squash_merge_commit_message` is `PR_BODY`. Stop and report the mismatch instead of merging if either setting differs.
5. Run `gh pr merge` with `--squash` and `--match-head-commit`, relying on the verified repository settings for the squash commit title and body. Do not pass `--subject` or `--body`, and do not use `--delete-branch` yet because the head branch may still be attached to a linked worktree.
6. Query the pull request again and verify GitHub reports it as merged. Record and report the resulting squash commit OID.
7. Locate the primary/base worktree and any linked worktree that has the pull request head branch checked out using `git worktree list --porcelain`. Perform cleanup from outside the feature worktree:
   - Update the base branch from its remote with a fast-forward-only pull. Preserve and reapply any unrelated local changes rather than discarding them.
   - If the feature worktree is dirty, do not force-remove it; report the remaining cleanup instead. If it is clean, remove it with `git worktree remove`.
   - After merge verification and worktree removal, delete the local head branch. Because a squash merge does not make the feature tip an ancestor of the base branch, targeted `git branch -D <head-branch>` is authorized here after all checks above pass.
   - For a same-repository pull request, delete the remote head branch if it still exists. Never attempt to delete a branch in a contributor's fork, the base branch, or a protected branch.
   - Run `git worktree prune` and verify the removed worktree and branch are gone.
8. Report the pull request number and URL, squash commit subject and OID, base-branch update, and worktree/local/remote branch cleanup results. Do not claim cleanup succeeded if any part was skipped.
