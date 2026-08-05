#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset

pkgname=$INPUT_PKGNAME
pkgbuild=$INPUT_PKGBUILD
assets=$INPUT_ASSETS
commit_username=$INPUT_COMMIT_USERNAME
commit_email=$INPUT_COMMIT_EMAIL
ssh_private_key=$INPUT_SSH_PRIVATE_KEY
commit_message=$INPUT_COMMIT_MESSAGE
allow_empty_commits=$INPUT_ALLOW_EMPTY_COMMITS
force_push=$INPUT_FORCE_PUSH
ssh_keyscan_types=$INPUT_SSH_KEYSCAN_TYPES
update_pkgver=$INPUT_UPDATE_PKGVER
push_retries=${INPUT_PUSH_RETRIES:-12}
push_retry_seconds=${INPUT_PUSH_RETRY_SECONDS:-20}

assert_non_empty() {
  name=$1
  value=$2
  if [[ -z "$value" ]]; then
    echo "::error::Invalid Value: $name is empty." >&2
    exit 1
  fi
}

assert_non_empty inputs.pkgname "$pkgname"
assert_non_empty inputs.pkgbuild "$pkgbuild"
assert_non_empty inputs.commit_username "$commit_username"
assert_non_empty inputs.commit_email "$commit_email"
assert_non_empty inputs.ssh_private_key "$ssh_private_key"

# Ignore "." and ".." to prevent errors when glob pattern for assets matches hidden files
GLOBIGNORE=".:.."

# Drop DSA — modern OpenSSH rejects it ("Unknown key type dsa").
# Must filter whole tokens only (naive ${var//dsa/} corrupts "ecdsa").
_filtered_types=()
IFS=',' read -ra _raw_types <<<"$ssh_keyscan_types"
for _t in "${_raw_types[@]}"; do
  _t_trimmed="${_t// /}"
  if [[ -n "$_t_trimmed" && "$_t_trimmed" != "dsa" ]]; then
    _filtered_types+=("$_t_trimmed")
  fi
done
if [[ ${#_filtered_types[@]} -eq 0 ]]; then
  ssh_keyscan_types="rsa,ecdsa,ed25519"
else
  ssh_keyscan_types=$(IFS=,; echo "${_filtered_types[*]}")
fi
echo "ssh-keyscan types: $ssh_keyscan_types"
echo '::group::Adding aur.archlinux.org to known hosts'
ssh-keyscan -v -t "$ssh_keyscan_types" aur.archlinux.org >>~/.ssh/known_hosts
echo '::endgroup::'

echo '::group::Importing private key'
echo "$ssh_private_key" >~/.ssh/aur
chmod -vR 600 ~/.ssh/aur*
ssh-keygen -vy -f ~/.ssh/aur >~/.ssh/aur.pub
echo '::endgroup::'

echo '::group::Checksums of SSH keys'
sha512sum ~/.ssh/aur ~/.ssh/aur.pub
echo '::endgroup::'

echo '::group::Configuring Git'
git config --global user.name "$commit_username"
git config --global user.email "$commit_email"
echo '::endgroup::'

echo '::group::Cloning AUR package into /tmp/local-repo'
# Prefer SSH clone (works for empty packages owned by this key). Fall back to HTTPS.
if ! git clone -v "ssh://aur@aur.archlinux.org/${pkgname}.git" /tmp/local-repo 2>/tmp/clone.err; then
  echo "SSH clone failed; trying HTTPS..."
  cat /tmp/clone.err || true
  rm -rf /tmp/local-repo
  git clone -v "https://aur.archlinux.org/${pkgname}.git" /tmp/local-repo
fi
echo '::endgroup::'

echo '::group::Copying files into /tmp/local-repo'
{
  echo "Copying $pkgbuild"
  cp -r "$pkgbuild" /tmp/local-repo/
}
# shellcheck disable=SC2086
# Ignore quote rule because we need to expand glob patterns to copy $assets
if [[ -n "$assets" ]]; then
  echo 'Copying' $assets
  cp -vrt /tmp/local-repo/ $assets
fi
echo '::endgroup::'

if [ "$update_pkgver" = "true" ]; then
  echo '::group::Updating pkgver'
  echo 'Running `makepkg -od` to update pkgver'

  tmp_makepkg=$(mktemp -d)
  cp -r /tmp/local-repo/. "$tmp_makepkg"
  (cd "$tmp_makepkg" && makepkg -od)

  cp "$tmp_makepkg/PKGBUILD" /tmp/local-repo/

  echo '::endgroup::'
fi

echo '::group::Generating .SRCINFO'
cd /tmp/local-repo
makepkg --printsrcinfo >.SRCINFO
echo '::endgroup::'

echo '::group::Committing files to the repository'
if [[ -z "$assets" ]]; then
  git add -fv PKGBUILD .SRCINFO
else
  git add --all
fi

# Empty AUR repos have no HEAD yet — git diff-index HEAD would fail.
has_head=false
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  has_head=true
fi

case "$allow_empty_commits" in
true)
  git commit --allow-empty -m "$commit_message"
  ;;
false)
  if [[ "$has_head" == "true" ]]; then
    git diff-index --quiet HEAD || git commit -m "$commit_message"
  else
    # Root commit for brand-new AUR packages
    git commit -m "$commit_message"
  fi
  ;;
*)
  echo "::error::Invalid Value: inputs.allow_empty_commits is neither 'true' nor 'false': '$allow_empty_commits'"
  exit 2
  ;;
esac
echo '::endgroup::'

echo '::group::Publishing the repository'
if ! git remote get-url aur >/dev/null 2>&1; then
  git remote add aur "ssh://aur@aur.archlinux.org/${pkgname}.git"
fi

# Prefer current branch name (empty clone defaults to master)
branch=$(git rev-parse --abbrev-ref HEAD)

push_args=(-v)
if [[ "$force_push" == "true" ]]; then
  push_args+=(--force)
elif [[ "$force_push" != "false" ]]; then
  echo "::error::Invalid Value: inputs.force_push is neither 'true' nor 'false': '$force_push'"
  exit 3
fi

ok=false
for attempt in $(seq 1 "$push_retries"); do
  echo "Push attempt $attempt/$push_retries to aur ($branch)..."
  if git push "${push_args[@]}" aur "$branch" 2>/tmp/aur-push.err; then
    ok=true
    break
  fi
  err=$(cat /tmp/aur-push.err || true)
  echo "$err"
  if echo "$err" | grep -qi 'maintenance\|Could not read from remote\|Connection refused\|timed out\|Connection reset'; then
    echo "::warning::AUR push failed (likely maintenance/network); waiting ${push_retry_seconds}s..."
    sleep "$push_retry_seconds"
    continue
  fi
  # Non-retryable auth/permission errors still retry a few times (SSH flakes)
  if echo "$err" | grep -qi 'Permission denied\|access rights'; then
    echo "::warning::SSH/auth error; waiting ${push_retry_seconds}s before retry..."
    sleep "$push_retry_seconds"
    continue
  fi
  echo "::warning::Unexpected push error; waiting ${push_retry_seconds}s before retry..."
  sleep "$push_retry_seconds"
done

if [[ "$ok" != "true" ]]; then
  echo "::error::Failed to push to AUR after ${push_retries} attempts"
  exit 1
fi
echo '::endgroup::'
