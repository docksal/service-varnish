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

COPY default.vcl /opt/default.vcl
COPY docker-healthcheck.sh /usr/local/bin/docker-healthcheck.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN set -ex; \
	apk add --update --no-cache bash curl rsync; \
	case ${VERSION} in \
    	6.1) alpinever="3.9";; \
    	6.0) alpinever="3.8";; \
    	5.2) alpinever="3.7";; \
    	4.1) alpinever="3.6";; \
	esac; \
	mv /etc/apk/repositories /etc/apk/repositories.orig; \
	echo "http://dl-cdn.alpinelinux.org/alpine/v${alpinever}/main" >/etc/apk/repositories; \
	echo "http://dl-cdn.alpinelinux.org/alpine/v${alpinever}/community" >>/etc/apk/repositories; \
	apk add --update --no-cache varnish; \
	mv -f /etc/apk/repositories.orig /etc/apk/repositories; \
	rm -rf /var/cache/apk/*

EXPOSE 80
EXPOSE 6082

CMD ["docker-entrypoint.sh"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["docker-healthcheck.sh"]
