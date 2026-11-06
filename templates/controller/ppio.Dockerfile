FROM registry.cn-hangzhou.aliyuncs.com/ceerdecy/github-actions-controller:v0.1.2
USER root
COPY templates/controller/entrypoint.sh /usr/local/bin/ppio-actions-controller-entrypoint
RUN chmod 0755 /usr/local/bin/ppio-actions-controller-entrypoint
USER user
ENTRYPOINT ["/usr/local/bin/ppio-actions-controller-entrypoint"]
CMD []
