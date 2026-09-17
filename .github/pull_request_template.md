## What

<!-- One-line summary. Use a Conventional Commits title: feat:, fix:, docs:, chore:, ci:, test:, perf:. -->

## Why

<!-- Link the issue (Closes #N) or explain the motivation. -->

## Checklist

- [ ] `shellcheck build.sh entrypoint.sh tests/run.sh` passes
- [ ] `bash tests/run.sh` passes
- [ ] `docker build -t aur-publish:dev .` succeeds
- [ ] `actionlint .github/workflows/*.yml` passes (if workflows changed)
- [ ] README updated (if inputs, outputs, or behavior changed)
- [ ] CHANGELOG entry added under `[Unreleased]` (if user-facing)
- [ ] No secrets or private keys in logs or fixtures
