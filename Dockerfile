ARG UPSTREAM_IMAGE
FROM ${UPSTREAM_IMAGE}

ARG TARGETARCH

# Install aditional dependencies
ARG GOMPLATE_VERSION=3.10.0
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends curl net-tools; \
	rm -rf /var/lib/apt/lists/*; \
	curl -sSLf -o /usr/local/bin/gomplate https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-${TARGETARCH}-slim; \
	chmod 755 /usr/local/bin/gomplate

COPY conf/default.vcl.tmpl /etc/varnish/default.vcl.tmpl
COPY docker-entrypoint.d /etc/docker-entrypoint.d/
COPY bin /usr/local/bin/

ENV VARNISH_PORT 80
ENV VARNISH_ADMIN_PORT 6082
ENV VARNISH_BACKEND_HOST web
ENV VARNISH_BACKEND_PORT 80
ENV VARNISH_CACHE_SIZE 64M
# See https://varnish-cache.org/docs/4.1/reference/varnishd.html
ENV VARNISH_VARNISHD_PARAMS ''
# See https://varnish-cache.org/docs/4.1/reference/varnishncsa.html
ENV VARNISH_VARNISHNCSA_PARAMS ''
ENV VARNISH_CACHE_TAGS_HEADER Cache-Tags

EXPOSE 80
EXPOSE 6082

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["varnishd.sh"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["docker-healthcheck.sh"]
