#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset

echo '::group::Creating builder user'
useradd --create-home --shell /bin/bash builder
passwd --delete builder
echo '::endgroup::'

echo '::group::Initializing SSH directory'
mkdir -pv /home/builder/.ssh
touch /home/builder/.ssh/known_hosts
cp -v /ssh_config /home/builder/.ssh/config
chown -vR builder:builder /home/builder
chmod -vR 600 /home/builder/.ssh/*
echo '::endgroup::'

# Docker actions run this entrypoint as root, but package work runs as the
# unprivileged builder. GitHub mounts GITHUB_OUTPUT as a runner-owned file, so
# stage outputs for builder and append them after it exits.
# begin-tests:output-transfer
transfer_github_output() {
  local source_path=$1 target_path=$2
  [[ -f "$source_path" ]] || return 0
  cat -- "$source_path" >>"$target_path"
}
# end-tests:output-transfer

github_output_target=${GITHUB_OUTPUT:-}
if [[ -n "$github_output_target" ]]; then
  github_output_staging=$(mktemp /tmp/aur-github-output.XXXXXX)
  chown builder:builder "$github_output_staging"
  export GITHUB_OUTPUT="$github_output_staging"
fi

runuser builder --command 'bash -l -c /build.sh'

if [[ -n "$github_output_target" ]]; then
  transfer_github_output "$github_output_staging" "$github_output_target"
  rm -f "$github_output_staging"
fi
