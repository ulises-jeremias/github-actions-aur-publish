# Examples

Copy-paste workflows for common setups. All pins use `@v1`; swap in an exact
tag (e.g. `v1.1.0`) to freeze the version. Secrets referenced throughout:
`AUR_USERNAME`, `AUR_EMAIL`, `AUR_SSH_PRIVATE_KEY`.

## Tag release with automatic pkgver

The tag drives the version: `update_pkgver` refreshes `pkgver` from the
`pkgver()` function, and the outputs feed a release summary.

```yaml
name: aur-publish

on:
  push:
    tags:
      - "v*"

jobs:
  aur-publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Publish AUR package
        id: aur
        uses: ulises-jeremias/github-actions-aur-publish@v1
        with:
          pkgname: my-awesome-package
          pkgbuild: ./PKGBUILD
          commit_username: ${{ secrets.AUR_USERNAME }}
          commit_email: ${{ secrets.AUR_EMAIL }}
          ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
          commit_message: "Release ${{ github.ref_name }}"
          update_pkgver: "true"
          allow_empty_commits: "false"

      - name: Summary
        run: |
          echo "Published ${{ steps.aur.outputs.package_version }}: ${{ steps.aur.outputs.package_url }}"
```

## Safe trial with dry_run

Validate a PKGBUILD or workflow change without touching the AUR. Handy as a
required check on pull requests.

```yaml
name: aur-dry-run

on:
  pull_request:
    paths:
      - "PKGBUILD"
      - "aur-package/**"

jobs:
  dry-run:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Preview publish
        uses: ulises-jeremias/github-actions-aur-publish@v1
        with:
          pkgname: my-awesome-package
          pkgbuild: ./PKGBUILD
          commit_username: "ci"
          commit_email: "ci@example.com"
          ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
          dry_run: "true"
```

> **Note:** `dry_run` still clones the AUR repository (a valid key is needed)
> — only the commit and push are skipped.

## Scheduled republish with checksums refresh

Re-resolve floating sources on a schedule. Push retries ride out AUR
maintenance windows.

```yaml
name: aur-refresh

on:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:

jobs:
  aur-publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Publish AUR package
        uses: ulises-jeremias/github-actions-aur-publish@v1
        with:
          pkgname: my-awesome-package
          pkgbuild: ./PKGBUILD
          commit_username: ${{ secrets.AUR_USERNAME }}
          commit_email: ${{ secrets.AUR_EMAIL }}
          ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
          commit_message: "Weekly checksum refresh"
          updpkgsums: "true"
          test: "true"
          allow_empty_commits: "false"
          push_retries: "24"
          push_retry_seconds: "30"
```

## Exact-mirror directory

Keep the AUR repository identical to a directory (removals propagate),
validating the result with a trial build.

```yaml
      - name: Publish AUR package
        uses: ulises-jeremias/github-actions-aur-publish@v1
        with:
          pkgname: my-awesome-package
          asset_dir: ./aur-package/my-awesome-package
          commit_username: ${{ secrets.AUR_USERNAME }}
          commit_email: ${{ secrets.AUR_EMAIL }}
          ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
          test: "true"
          allow_empty_commits: "false"
```
