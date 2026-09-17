# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
follows the versioning policy described in [`README.md`](./README.md#releases).

Starting with the next tagged release, entries below are filled in from the
draft release [Release Drafter](https://github.com/release-drafter/release-drafter)
maintains automatically from merged pull request labels - see the workflow in
[`.github/workflows/release-drafter.yml`](./.github/workflows/release-drafter.yml).
Copy the draft's contents here as part of cutting a release.

## [Unreleased]

### Security

- Pinned third-party Actions by commit SHA in all workflows.
- CI now lints workflow files with actionlint.
- CI now lints the Dockerfile with hadolint (digest-pinned image).

### Added

- `asset_dir` input: exact-mirror mode for the AUR repository (must contain
  PKGBUILD; mutually exclusive with `pkgbuild`/`assets`). `pkgbuild` is now
  optional when `asset_dir` is used.
- `updpkgsums` input: refresh checksums with `updpkgsums` before publishing
  (adds `pacman-contrib` to the image).
- `test`/`test_flags` inputs: opt-in `makepkg` trial build before publishing
  (invalid values fail with exit code 5).
- `post_process` input: escape-hatch hook evaluated after processing the
  package, before committing.
- `dry_run` input: prepare and preview the publish without committing or
  pushing (invalid values fail with exit code 6).
- `package_version` output: `pkgver` of the published package.
- `tests/run.sh`: durable behavior tests (input validation, PKGBUILD checks,
  action/README consistency), wired into CI.
- Bug/feature issue forms and a PR checklist template.
- Pre-commit config (whitespace, YAML, ShellCheck, behavior tests) plus
  EditorConfig.

## [v1.1.0] - 2026-09-17

### Added

- `aur_branch` input (default `master`) instead of a hardcoded push branch.
- Action outputs `commit_sha` and `package_url`.
- PKGBUILD validation in `build.sh` (`bash -n` plus required-field checks).
- CI workflow (`.github/workflows/ci.yml`) with ShellCheck, action metadata
  validation, and Docker build.
- `CONTRIBUTING.md` contributor guide.
- `.dockerignore` and digest-pinned base image (managed by Renovate).
- README sections: Outputs, `assets` and matrix examples, permissions guidance,
  Troubleshooting, Used by, and Acknowledgments.
- README Used by: added Create-Rust-App/aur-package (automation via its PR #8).

## [v1] - 2022-01-14

Initial public release. `v1` is a rolling major tag that has since absorbed
several fixes without an individual changelog entry per change - see the
[commit history](https://github.com/ulises-jeremias/github-actions-aur-publish/commits/v1)
or [merged pull requests](https://github.com/ulises-jeremias/github-actions-aur-publish/pulls?q=is%3Apr+is%3Amerged)
for the full detail up to this point.

[Unreleased]: https://github.com/ulises-jeremias/github-actions-aur-publish/compare/v1.1.0...HEAD
[v1.1.0]: https://github.com/ulises-jeremias/github-actions-aur-publish/releases/tag/v1.1.0
[v1]: https://github.com/ulises-jeremias/github-actions-aur-publish/releases/tag/v1
