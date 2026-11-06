FROM registry.cn-hangzhou.aliyuncs.com/ceerdecy/github-actions-runner:v0.1.2
# Outbound HTTP proxy for everything the runner and its jobs download
# (actions archives from codeload.github.com, package registries). Direct
# egress from the Sandbox is too slow for the runner's 100 s download timeout.
# Lower-case and upper-case forms are both set because tools differ in which
# one they read. no_proxy keeps loopback and the PPIO platform itself direct.
ARG RUNNER_HTTP_PROXY=http://10.97.197.11:1081
ENV http_proxy=${RUNNER_HTTP_PROXY} \
    https_proxy=${RUNNER_HTTP_PROXY} \
    HTTP_PROXY=${RUNNER_HTTP_PROXY} \
    HTTPS_PROXY=${RUNNER_HTTP_PROXY} \
    no_proxy=localhost,127.0.0.1,::1,.sandbox.ppio.com,.sandbox.ppio.cn \
    NO_PROXY=localhost,127.0.0.1,::1,.sandbox.ppio.com,.sandbox.ppio.cn
# Preinstall a C toolchain so native build scripts (Rust `cc`, Python wheels,
# Node native addons) can link. The base image is debian:bookworm-slim and
# contains no linker; without this, `cargo build` fails with "linker `cc` not found".
USER root
# The ENV above is not reliably visible to the template builder's RUN steps, so
# pass the proxy to apt-get explicitly as well.
RUN http_proxy=${RUNNER_HTTP_PROXY} https_proxy=${RUNNER_HTTP_PROXY} \
    apt-get update \
    && http_proxy=${RUNNER_HTTP_PROXY} https_proxy=${RUNNER_HTTP_PROXY} \
    apt-get install -y --no-install-recommends \
      build-essential pkg-config libssl-dev zstd \
    && rm -rf /var/lib/apt/lists/*
USER user
CMD ["/home/user/actions-runner/entrypoint.sh"]
