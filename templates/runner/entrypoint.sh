#!/usr/bin/env bash
set -euo pipefail
cd /home/user/actions-runner

# PPIO's egress proxy terminates TLS with its own root CA and advertises the
# bundle through these variables at Sandbox creation. A Template start command
# is restored from the build snapshot and does not inherit that environment, so
# git and curl inside jobs would fail certificate verification. Re-export the
# bundle when it is present; outside PPIO the system store is used unchanged.
proxy_ca_bundle=/etc/sandbox/proxy-ca-bundle.pem
if [[ -r "$proxy_ca_bundle" ]]; then
  export SSL_CERT_FILE="$proxy_ca_bundle"
  export CURL_CA_BUNDLE="$proxy_ca_bundle"
  export REQUESTS_CA_BUNDLE="$proxy_ca_bundle"
  export GIT_SSL_CAINFO="$proxy_ca_bundle"
  export NODE_EXTRA_CA_CERTS="${NODE_EXTRA_CA_CERTS:-/etc/sandbox/proxy-root-ca.pem}"
fi

jit_file=.jitconfig
until [[ -s "$jit_file" ]]; do sleep 0.2; done
export ACTIONS_RUNNER_INPUT_JITCONFIG
ACTIONS_RUNNER_INPUT_JITCONFIG="$(<"$jit_file")"
rm -f "$jit_file"
exec ./run.sh
