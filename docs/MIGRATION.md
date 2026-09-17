# Migrating from KSXGitHub/github-actions-deploy-aur

This action covers the same workflow with a compatible input surface, plus
extras (`aur_branch`, `dry_run`, `package_version` output, PKGBUILD
validation). Most migrations are a drop-in `uses:` swap.

## Step substitution

```diff
       - name: Publish to AUR
-        uses: KSXGitHub/github-actions-deploy-aur@v3
+        uses: ulises-jeremias/github-actions-aur-publish@v1
         with:
           pkgname: my-awesome-package
           pkgbuild: ./PKGBUILD
```

## Input mapping

| KSX input          | This action       | Notes                                                  |
|--------------------|-------------------|--------------------------------------------------------|
| `pkgname`          | `pkgname`         | Same.                                                  |
| `pkgbuild`         | `pkgbuild`        | Same; optional here when `asset_dir` is used.          |
| `assets`           | `assets`          | Same additive-glob semantics.                          |
| `asset_dir`        | `asset_dir`       | Same exact-mirror semantics.                           |
| `updpkgsums`       | `updpkgsums`      | Same.                                                  |
| `test`             | `test`            | Same.                                                  |
| `test_flags`       | `test_flags`      | Same default (`--clean --cleanbuild --nodeps`).        |
| `post_process`     | `post_process`    | Same `eval` hook.                                      |
| `commit_username`  | `commit_username` | Same.                                                  |
| `commit_email`     | `commit_email`    | Same.                                                  |
| `ssh_private_key`  | `ssh_private_key` | Same.                                                  |
| `commit_message`   | `commit_message`  | Same default text.                                     |
| `force_push`       | `force_push`      | Same.                                                  |
| `ssh_keyscan_types`| `ssh_keyscan_types`| Same; `dsa` is filtered automatically here.           |

## Behavior differences

- `allow_empty_commits` defaults to `true` here (KSX defaults to `false`).
  Set it to `"false"` explicitly to keep KSX behavior and skip no-op pushes.
- PKGBUILD validation runs before every publish here (`bash -n` plus
  required-field checks, exit code 4). Workflows relying on publishing
  unchecked files will now fail early with a named error.
- Invalid `test` / `dry_run` values fail with distinct exit codes
  (5 and 6) instead of proceeding.
- Push failures are retried (`push_retries`, default 12, every
  `push_retry_seconds`, default 20s) to ride out AUR maintenance windows.
- Outputs `commit_sha`, `package_url`, and `package_version` are available
  here for downstream steps.

## Suggested rollout

1. Point a copy of the workflow at this action with `dry_run: "true"` and
   confirm the preview output.
2. Remove `dry_run`, publish once, and compare the AUR commit with the
   previous publisher's result.
3. Delete the old step.
