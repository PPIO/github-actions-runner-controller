#!/usr/bin/env bash
set -euo pipefail

# PPIO runs the template command once while building the template, before any
# runtime environment exists. Wait in that build-only state; a real Control
# Sandbox receives these values atomically at creation and starts immediately.
while [[ -z "${GITHUB_CONFIG_URL:-}" || -z "${PPIO_RUNNER_TEMPLATE:-}" ]]; do
  sleep 1
done
exec /usr/local/bin/ppio-actions-controller
