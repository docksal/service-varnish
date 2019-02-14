FROM alpine:3.9

ARG VERSION
ENV VERSION=${VERSION}
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

COPY patches /tmp/patches/
COPY config /tmp/config/
COPY scripts /tmp/scripts/
COPY docker-healthcheck.sh /usr/local/bin/docker-healthcheck.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN set -ex; \
    apk add --update --no-cache bash; \
    /tmp/scripts/build

EXPOSE 80
EXPOSE 6082

CMD ["docker-entrypoint.sh"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["docker-healthcheck.sh"]
