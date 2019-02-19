#!/bin/bash

set -e # Fail on errors

# Generate config from template
default_vcl="/etc/varnish/default.vcl.tmpl"
custom_vcl="/var/www/.docksal/etc/varnish/default.vcl"

if [[ -f ${custom_vcl} ]]; then
	echo "Generating config from a custom VCL in ${custom_vcl}..."
	vcl_template=${custom_vcl}
else
	echo 'Using default VCL...'
	vcl_template=${default_vcl}
fi

gomplate --file ${vcl_template} --out /etc/varnish/default.vcl

# Set Varnish secret if provided
if [[ "${VARNISH_SECRET}" != "" ]]; then
	echo "${VARNISH_SECRET}" > /etc/varnish/secret
	VARNISH_VARNISHD_PARAMS="${VARNISH_VARNISHD_PARAMS} -S /etc/varnish/secret"
fi
