# Contributing

Thanks for helping improve `github-actions-aur-publish`. This guide covers the
basics for first-time contributors.

## Local setup

1. Clone the repository:

   ```bash
   git clone https://github.com/ulises-jeremias/github-actions-aur-publish
   cd github-actions-aur-publish
   ```

2. Build the Docker image:

   ```bash
   docker build -t aur-publish:dev .
   ```

No other dependencies are required. The action itself runs inside the
Arch Linux container.

## Testing changes

- Run ShellCheck on both scripts:

  ```bash
  shellcheck build.sh entrypoint.sh
  ```

- Run the behavior tests:

  ```bash
  bash tests/run.sh
  ```

- Validate the action metadata:

  ```bash
  python3 -c "import yaml; yaml.safe_load(open('action.yml'))"
  ```

- Verify the Docker image still builds:

  ```bash
  docker build -t aur-publish:dev .
  ```

- For `PKGBUILD` validation changes, test with a minimal PKGBUILD containing
  `pkgname`, `pkgver`, `pkgrel`, `arch`, and `license`, plus one with a syntax
  error to confirm the workflow fails with a clear message.

## PR checklist

- [ ] ShellCheck passes (`shellcheck build.sh entrypoint.sh`)
- [ ] Tests pass (`bash tests/run.sh`)
- [ ] Docker image builds (`docker build -t aur-publish:dev .`)
- [ ] `README.md` updated if inputs, outputs, or behavior changed
- [ ] `CHANGELOG.md` entry added under `[Unreleased]` for user-facing changes

## Pinned actions

Third-party Actions are pinned by commit SHA (with the tag as a trailing
comment, e.g. `actions/checkout@<sha> # v4`). Renovate updates the pins —
never float a `uses:` back to a bare tag.

## Commit conventions

- Use [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `docs:`, `chore:`, `perf:`, `ci:`.
- Keep commits focused; one logical change per commit.
- Release notes are generated automatically by Release Drafter from PR labels,
  so use a clear PR title with the same prefix style.
