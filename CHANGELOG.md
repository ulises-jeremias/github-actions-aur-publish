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

## [v1] - 2022-01-14

Initial public release. `v1` is a rolling major tag that has since absorbed
several fixes without an individual changelog entry per change - see the
[commit history](https://github.com/ulises-jeremias/github-actions-aur-publish/commits/v1)
or [merged pull requests](https://github.com/ulises-jeremias/github-actions-aur-publish/pulls?q=is%3Apr+is%3Amerged)
for the full detail up to this point.

[Unreleased]: https://github.com/ulises-jeremias/github-actions-aur-publish/compare/v1...HEAD
[v1]: https://github.com/ulises-jeremias/github-actions-aur-publish/releases/tag/v1
