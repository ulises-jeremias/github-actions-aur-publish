# Publish AUR package

GitHub Actions to publish AUR package.

## Inputs

- `pkgname`

**Required** AUR package name.

- `pkgbuild`

**Required** Path to PKGBUILD file. This file is often generated by prior steps.

- `assets`

**Optional** Newline-separated glob patterns for additional files to be added to the AUR repository.
Glob patterns will be expanded by bash when copying the files to the repository.

- `commit_username`

**Required** The username to use when creating the new commit.

- `commit_email`

**Required** The email to use when creating the new commit.

- `ssh_private_key`

**Required** Your private key with access to AUR package.

- `commit_message`

**Optional** Commit message to use when creating the new commit.

- `allow_empty_commits`

**Optional** Allow empty commits, i.e. commits with no change. The default value is `true`.

- `force_push`

**Optional** Use `--force` when push to the AUR. The default value is `false`.

- `ssh_keyscan_types`

**Optional** Comma-separated list of types to use when adding aur.archlinux.org to known hosts.

- `update_pkgver`

**Optional** Run `makepkg -od` to update `pkgver`. Requires that the `pkgver()` function defined in the `PKGBUILD` file doesn't required any dependencies other than git. The default value is `false`.

## Example usage

```yaml
name: aur-publish

on:
  push:
    tags:
      - "*"

jobs:
  aur-publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Publish AUR package
        uses: ulises-jeremias/github-actions-aur-publish@<TAG>
        with:
          pkgname: my-awesome-package
          pkgbuild: ./PKGBUILD
          commit_username: ${{ secrets.AUR_USERNAME }}
          commit_email: ${{ secrets.AUR_EMAIL }}
          ssh_private_key: ${{ secrets.AUR_SSH_PRIVATE_KEY }}
          commit_message: Update AUR package
          ssh_keyscan_types: rsa,dsa,ecdsa,ed25519
          update_pkgver: false
```

**Note:** Replace `<TAG>` in the above code snippet with a tag of this repo.

**Tip:** To create secrets (such as `secrets.AUR_USERNAME`, `secrets.AUR_EMAIL`, and `secrets.AUR_SSH_PRIVATE_KEY` above), go to `$YOUR_GITHUB_REPO_URL/settings/secrets`. [Read this for more information](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).

**Tip:** This action does not generate PKGBUILD for you, you must generate it yourself (e.g. by using actions before this action).

## License

[MIT](https://github.com/ulises-jeremias/github-actions-aur-publish/blob/main/LICENSE)
