#!/bin/bash

echo 'Starting varnishd...'
exec varnishd \
	-f /etc/varnish/default.vcl \
	-s malloc,${VARNISH_CACHE_SIZE} \
	-a :${VARNISH_PORT} \
	-T :${VARNISH_ADMIN_PORT} \
	${VARNISH_VARNISHD_PARAMS}
