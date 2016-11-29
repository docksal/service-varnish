FROM alpine:3.4

MAINTAINER Leonid Makarov <leonid.makarov@blinkreaction.com>

RUN apk add --update --no-cache bash varnish && \
	rm -rf /var/cache/apk/*

COPY default.vcl /opt/default.vcl
COPY startup.sh /opt/startup.sh

ENV VARNISH_PORT 80
ENV VARNISH_BACKEND_PORT 80
ENV VARNISH_CACHE_SIZE 64M
ENV VARNISH_VARNISHLOG_PARAMS '-c -I RespStatus:^50'

EXPOSE 80

CMD ["/opt/startup.sh"]
