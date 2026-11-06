#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/hosted-common.sh
source "$script_dir/hosted-common.sh"
# Brokered Secrets require the v2 region; pin it unless the caller overrides.
export PPIO_DOMAIN=${PPIO_DOMAIN:-cn-beijing-1.sandbox.ppio.com}
hosted_require_ppio_cli

sandbox_id=${1:-}
timeout=${CONTROL_TIMEOUT:-525600h}
if [[ -z "$sandbox_id" ]]; then
  : "${GITHUB_CONFIG_URL:?usage: scripts/resume-hosted.sh SANDBOX_ID, or set GITHUB_CONFIG_URL}"
  github_config_url=$(hosted_normalize_github_config_url "$GITHUB_CONFIG_URL")
  target_id=$(hosted_target_id "$github_config_url")
  controller_id=${CONTROLLER_ID:-ppio-hosted-$target_id}
  resolved=$(hosted_resolve_controller "$target_id" "$controller_id")
  state=
  if [[ -n "$resolved" ]]; then
    read -r state sandbox_id <<<"$resolved"
  fi
  [[ -n "$sandbox_id" ]] || {
    printf 'no Control Sandbox found for target %s\n' "$target_id" >&2
    exit 1
  }
else
  state=$(hosted_sandbox_state "$sandbox_id")
fi

# PPIO resume defaults the new lifetime to about five minutes and does not
# take a timeout flag. Always restore the intended long-running timeout with
# set-timeout right after resuming, then verify the controller.
if [[ "$state" == paused ]]; then
  ppio sandbox resume "$sandbox_id" >/dev/null
  ppio sandbox set-timeout "$sandbox_id" "$timeout" >/dev/null
fi
for attempt in {1..30}; do
  if ppio sandbox exec "$sandbox_id" -- python -c \
    'import urllib.request; assert urllib.request.urlopen("http://127.0.0.1:8080/healthz", timeout=2).status == 200' \
    >/dev/null 2>&1; then
    ppio sandbox info "$sandbox_id" --output json
    exit 0
  fi
  sleep 2
done
printf 'Hosted controller did not recover in Sandbox %s\n' "$sandbox_id" >&2
exit 1
