#!/usr/bin/env bash
set -euo pipefail

image=${AUR_PUBLISH_TEST_IMAGE:-aur-publish:ci}
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/file_commands"
printf 'existing=value\n' > "$tmp_dir/file_commands/output"

cat > "$tmp_dir/fake-build.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$GITHUB_OUTPUT" == "$RUNNER_OUTPUT_TARGET" ]]; then
  echo 'builder received the runner-owned output path directly' >&2
  exit 70
fi
if [[ -w "$RUNNER_OUTPUT_TARGET" ]]; then
  echo 'builder can unexpectedly write the runner-owned output file' >&2
  exit 71
fi

printf 'commit_sha=test123\npackage_version=1.2.3\n' >>"$GITHUB_OUTPUT"
EOF
chmod +x "$tmp_dir/fake-build.sh"

# Give the output file to a UID different from the container's `builder` user
# to reproduce the Actions runner mount permissions in an isolated container.
docker run --rm \
  --entrypoint sh \
  -v "$tmp_dir/file_commands:/github/file_commands" \
  "$image" \
  -c 'chown 2000:2000 /github/file_commands/output && chmod 0644 /github/file_commands/output'

docker run --rm \
  -e GITHUB_OUTPUT=/github/file_commands/output \
  -e RUNNER_OUTPUT_TARGET=/github/file_commands/output \
  -v "$tmp_dir/file_commands:/github/file_commands" \
  -v "$tmp_dir/fake-build.sh:/build.sh:ro" \
  "$image"

cat > "$tmp_dir/expected" <<'EOF'
existing=value
commit_sha=test123
package_version=1.2.3
EOF
diff -u "$tmp_dir/expected" "$tmp_dir/file_commands/output"
echo 'Docker output bridge works across users.'
