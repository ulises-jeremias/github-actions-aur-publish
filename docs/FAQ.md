# Frequently asked questions

## Do I need to write the PKGBUILD myself?

Yes. This action publishes files, it does not generate them. Produce the
PKGBUILD in earlier steps (templates, scripts, or a mirror repo like
`Create-*/aur-package`), then hand its path to `pkgbuild` or `asset_dir`.

## `assets` or `asset_dir`?

- `assets`: extra files *added* on top of the PKGBUILD. Simple, but removals
  never propagate — deleting a file from `assets` leaves it in the AUR repo.
- `asset_dir`: the directory *is* the repository (must contain the PKGBUILD).
  Removals propagate. Use it when the AUR package has several files.

## Why did my run push an empty commit?

`allow_empty_commits` defaults to `true`, so a no-change run still pushes an
empty commit. Set it to `"false"` to skip pushes with no diff.

## Why was `dsa` removed from my `ssh_keyscan_types`?

Modern OpenSSH rejects DSA (`Unknown key type dsa`). The action filters the
`dsa` token automatically (whole-token only, so `ecdsa` is untouched) and
falls back to `rsa,ecdsa,ed25519` if nothing valid remains.

## The push failed during AUR maintenance. What now?

Nothing — the action retries (`push_retries`, default 12, every
`push_retry_seconds`, default 20s) and only fails after exhausting them.
Re-run later or raise `push_retries` for long windows.

## `test: true` fails on dependencies. Why?

The trial build runs `makepkg` with `test_flags` (default
`--clean --cleanbuild --nodeps`). Source builds needing toolchains or
libraries must either keep `--nodeps` semantics or install deps via
`post_process` before the test runs.

## Which tag should I pin?

- `@v1` (rolling): receives non-breaking fixes automatically — what most
  consumers use.
- `@v1.1.0` (exact, immutable): only changes you explicitly review.

## How do downstream steps use the result?

```yaml
- uses: ulises-jeremias/github-actions-aur-publish@v1
  id: aur
  with: # ...
- run: echo "Published ${{ steps.aur.outputs.package_version }} ${{ steps.aur.outputs.package_url }}"
```

## Can I try a change without publishing?

Yes: `dry_run: "true"` runs validation, preparation, and the preview, then
exits before committing. A valid SSH key is still needed because the AUR
repository is cloned first.
