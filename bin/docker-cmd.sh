#!/bin/bash

echo 'Starting varnishd...'
varnishd \
	-f /etc/varnish/default.vcl \
	-s malloc,${VARNISH_CACHE_SIZE} \
	-a :${VARNISH_PORT} \
	-T :${VARNISH_ADMIN_PORT} \
	${VARNISH_VARNISHD_PARAMS}

echo 'Streaming logs (varnishncsa)...'
varnishncsa ${VARNISH_VARNISHNCSA_PARAMS}
