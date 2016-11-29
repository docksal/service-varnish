#!/bin/bash

# Delay start to avoid DNS lookup issues
echo 'Waiting 5s before startup...'
sleep 5

echo 'Copying config from /opt/default.vcl...'
cp -f /opt/default.vcl /etc/varnish/default.vcl

echo 'Evaluating config variables...'
for name in VARNISH_BACKEND_PORT VARNISH_BACKEND_HOST VARNISH_BACKEND_DOMAIN
do
    eval value=\$$name
    sed -i "s|{${name}}|${value}|g" /etc/varnish/default.vcl
done

echo 'Starting varnishd...'
varnishd -f /etc/varnish/default.vcl -s malloc,${VARNISH_CACHE_SIZE} -a 0.0.0.0:${VARNISH_PORT} ${VARNISH_VARNISHD_PARAMS}

echo 'Starting varnishlog...'
varnishlog ${VARNISH_VARNISHLOG_PARAMS}
