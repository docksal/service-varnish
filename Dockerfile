FROM alpine:3.9

ARG VERSION
ENV VERSION=${VERSION}

RUN set -ex; \
	apk add --update --no-cache \
		bash \
		su-exec \
		supervisor \
	;\
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

# Install aditional dependencies
ARG GOMPLATE_VERSION=3.0.0
RUN set -xe; \
	apk add --no-cache -t .fetch-deps \
		curl \
	; \
	# gomplate - go templates in configs
	curl -sSL https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-amd64-slim -o /usr/local/bin/gomplate; \
	chmod +x /usr/local/bin/gomplate; \
	\
	apk del --purge .fetch-deps; \
	rm -rf /var/cache/apk/*

# Override the main supervisord config file, since some parameters are not overridable via an include
# See https://github.com/Supervisor/supervisor/issues/962
COPY conf/supervisord.conf /etc/supervisord.conf
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
CMD ["docker-cmd.sh"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["docker-healthcheck.sh"]
