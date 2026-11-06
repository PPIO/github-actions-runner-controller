#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/hosted-common.sh
source "$script_dir/hosted-common.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

normalized=$(hosted_normalize_github_config_url 'https://github.com/PPIO/Example.git/')
[[ "$normalized" == 'https://github.com/ppio/example' ]] || fail "URL normalization"
target_a=$(hosted_target_id "$normalized")
target_b=$(hosted_target_id 'https://github.com/ppio/example')
[[ "$target_a" == "$target_b" ]] || fail "stable target ID"
[[ "$target_a" == ppio-example-* ]] || fail "readable target ID"
if hosted_normalize_github_config_url 'https://github.com/ppio/example?wrong=1' >/dev/null 2>&1; then
  fail "invalid URL rejection"
fi
target_c=$(hosted_target_id 'https://github.com/ppio/another-repository')
[[ "$target_a" != "$target_c" ]] || fail "different target IDs"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
cat >"$test_dir/ppio" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == --version ]]; then
  printf '2.1.0\n'
  exit 0
fi
if [[ "${1:-}" == sandbox && "${2:-}" == list && "${FAKE_LIST_MODE:-}" == resume ]]; then
  if [[ " $* " == *" --state paused "* ]]; then
    printf '%s\n' '{"sandboxes":[{"sandboxId":"sandbox-paused"}]}'
  else
    printf '%s\n' '{"sandboxes":[]}'
  fi
  exit 0
fi
if [[ "${1:-}" == sandbox && ( "${2:-}" == resume || "${2:-}" == set-timeout ) ]]; then
  printf '%s\n' "$*" >>"${FAKE_LOG:?}"
  exit 0
fi
if [[ "${1:-}" == sandbox && "${2:-}" == exec ]]; then
  exit 0
fi
if [[ "${1:-}" == sandbox && "${2:-}" == info ]]; then
  printf '%s\n' "{\"sandboxId\":\"${3:-sandbox-paused}\",\"state\":\"${FAKE_INFO_STATE:-running}\"}"
  exit 0
fi
if [[ "${FAKE_LIST_MODE:-}" == ambiguous ]]; then
  printf '%s\n' '{"sandboxes":[{"sandboxId":"sandbox-a"},{"sandboxId":"sandbox-b"}]}'
else
  printf '%s\n' '{"sandboxes":[{"sandboxId":"sandbox-a"}]}'
fi
SH
chmod +x "$test_dir/ppio"
PATH="$test_dir:$PATH"
export PATH
hosted_require_ppio_cli
found=$(hosted_find_controller running "$target_a" "ppio-hosted-$target_a")
[[ "$found" == sandbox-a ]] || fail "unique controller lookup"
if FAKE_LIST_MODE=ambiguous hosted_find_controller running "$target_a" \
  "ppio-hosted-$target_a" >/dev/null 2>&1; then
  fail "ambiguous controller lookup"
fi

fake_log="$test_dir/ppio.log"
: >"$fake_log"
FAKE_LIST_MODE=resume FAKE_LOG="$fake_log" \
  GITHUB_CONFIG_URL="$normalized" CONTROL_TIMEOUT=123h \
  bash "$script_dir/resume-hosted.sh" >/dev/null
grep -Fqx 'sandbox resume sandbox-paused' "$fake_log" || \
  fail "target-based resume"
grep -Fqx 'sandbox set-timeout sandbox-paused 123h' "$fake_log" || \
  fail "target-based resume timeout"

: >"$fake_log"
FAKE_LOG="$fake_log" FAKE_INFO_STATE=running \
  bash "$script_dir/resume-hosted.sh" sandbox-running >/dev/null
[[ ! -s "$fake_log" ]] || fail "running Sandbox should not resume again"

printf 'Hosted script tests passed.\n'
