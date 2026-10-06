#!/usr/bin/env bash
# Durable behavior tests for github-actions-aur-publish.
# Exercises the real marked blocks in build.sh (no mocks of the logic).
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

pass=0
fail=0

check() {
  local desc=$1 expected=$2 actual=$3
  if [[ "$actual" == "$expected" ]]; then
    pass=$((pass + 1))
    echo "ok - $desc"
  else
    fail=$((fail + 1))
    echo "NOT OK - $desc (expected exit $expected, got $actual)"
  fi
}

extract() {
  sed -n "/# begin-tests:$1/,/# end-tests:$1/p" build.sh
}

# Real helpers from build.sh (no copies: the test fails if they change shape).
helpers() {
  sed -n '/^assert_non_empty() {/,/^}/p' build.sh
}

# --- fixtures ---
mkdir -p /tmp/gaap-tests
cat > /tmp/gaap-tests/PKGBUILD.good <<'EOF'
pkgname=foo
pkgver=1.0
pkgrel=1
arch=('any')
license=('MIT')
package() { :; }
EOF
printf 'pkgname=foo\npkgver=1.0\n' > /tmp/gaap-tests/PKGBUILD.bad
printf 'pkgname=foo\nif [\n' > /tmp/gaap-tests/PKGBUILD.syntax
mkdir -p /tmp/gaap-tests/assetdir
cp /tmp/gaap-tests/PKGBUILD.good /tmp/gaap-tests/assetdir/PKGBUILD
mkdir -p /tmp/gaap-tests/emptydir

# --- mutual exclusion (exit 1 on conflict, 0 when valid) ---
run_mutual() {
  local block
  block="$(helpers)
$(extract mutual-exclusion)"
  (bash -c "set -e; $block" >/dev/null 2>&1)
  echo $?
}

export asset_dir=/tmp/gaap-tests/assetdir pkgbuild='./PKGBUILD' assets=''
check "asset_dir + pkgbuild is rejected" 1 "$(run_mutual)"
export asset_dir=/tmp/gaap-tests/assetdir pkgbuild='' assets='./x'
check "asset_dir + assets is rejected" 1 "$(run_mutual)"
export asset_dir=/tmp/gaap-tests/emptydir pkgbuild='' assets=''
check "asset_dir without PKGBUILD is rejected" 1 "$(run_mutual)"
export asset_dir=/tmp/gaap-tests/assetdir pkgbuild='' assets=''
check "asset_dir with PKGBUILD is accepted" 0 "$(run_mutual)"
export asset_dir='' pkgbuild='' assets=''
check "missing pkgbuild without asset_dir is rejected" 1 "$(run_mutual)"
export asset_dir='' pkgbuild='./PKGBUILD' assets=''
check "pkgbuild alone is accepted" 0 "$(run_mutual)"

# --- PKGBUILD validation (exit 4 on invalid, 0 when valid) ---
run_validation() {
  local block
  block=$(extract pkgbuild-validation)
  (bash -c "effective_pkgbuild=$1; $block" >/dev/null 2>&1)
  echo $?
}

check "valid PKGBUILD passes" 0 "$(run_validation /tmp/gaap-tests/PKGBUILD.good)"
check "PKGBUILD missing fields fails" 4 "$(run_validation /tmp/gaap-tests/PKGBUILD.bad)"
check "PKGBUILD syntax error fails" 4 "$(run_validation /tmp/gaap-tests/PKGBUILD.syntax)"

# --- output bridge: transfer staged builder outputs to the runner file ---
output_transfer_block() {
  sed -n '/# begin-tests:output-transfer/,/# end-tests:output-transfer/p' entrypoint.sh
}

output_source=/tmp/gaap-tests/builder-output
output_target=/tmp/gaap-tests/github-output
printf 'commit_sha=abc123\npackage_version=1.2.3\n' > "$output_source"
printf 'existing=value\n' > "$output_target"
transfer=$(output_transfer_block)
if bash -c "$transfer
transfer_github_output '$output_source' '$output_target'"; then
  check "staged outputs transfer to the runner file" 0 0
else
  check "staged outputs transfer to the runner file" 0 1
fi
expected_output=$'existing=value\ncommit_sha=abc123\npackage_version=1.2.3'
actual_output=$(cat "$output_target")
check "output transfer appends without replacing existing values" "$expected_output" "$actual_output"

# --- action.yml / README consistency ---
if python3 - <<'EOF'
import sys
import yaml

meta = yaml.safe_load(open('action.yml'))
readme = open('README.md').read()
errors = []

for name, spec in meta['inputs'].items():
    if f'- `{name}`' not in readme and f'`{name}`' not in readme:
        errors.append(f'input {name} not documented in README')
for name in meta.get('outputs', {}):
    if f'`{name}`' not in readme:
        errors.append(f'output {name} not documented in README')
if 'runs' not in meta or meta['runs'].get('using') != 'docker':
    errors.append('action must use the docker runner')

if errors:
    print('\n'.join(f'NOT OK - {e}' for e in errors))
    sys.exit(1)
print(f"ok - action.yml/README consistency ({len(meta['inputs'])} inputs, {len(meta.get('outputs', {}))} outputs)")
EOF
then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
fi

echo "---"
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
