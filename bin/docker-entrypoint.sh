#!/bin/bash

set -eo pipefail
shopt -s nullglob

# Enable debug messaging by default, unless explicitly disabled
DEBUG=${DEBUG:-1}

echo_debug ()
{
	if [[ "$DEBUG" != 0 ]]; then echo -e "$(date +"%F %H:%M:%S") | $@"; fi
}


# Execute available init scripts
# This can be used by child images to run additional provisioning scripts at startup
ls /etc/docker-entrypoint.d/ > /dev/null
for script in /etc/docker-entrypoint.d/*.sh; do
	echo "$0: running ${script}"
	# Note: scripts are sourced (executed in the context of the parent script)
	. "${script}"
done
