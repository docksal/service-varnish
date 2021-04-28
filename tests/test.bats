#!/usr/bin/env bats

# Debugging
teardown () {
	echo
	echo "Output:"
	echo "================================================================"
	echo "${output}"
	echo "================================================================"
}

# Checks container health status (if available)
# @param $1 container id/name
_healthcheck ()
{
	local health_status
	health_status=$(${DOCKER} inspect --format='{{json .State.Health.Status}}' "$1" 2>/dev/null)

	# Wait for 5s then exit with 0 if a container does not have a health status property
	# Necessary for backward compatibility with images that do not support health checks
	if [[ $? != 0 ]]; then
		echo "Waiting 10s for container to start..."
		sleep 10
		return 0
	fi

	# If it does, check the status
	echo $health_status | grep '"healthy"' >/dev/null 2>&1
}

# Waits for containers to become healthy
_healthcheck_wait ()
{
	# Wait for cli to become ready by watching its health status
	local container_name="${NAME}"
	local delay=5
	local timeout=30
	local elapsed=0

	until _healthcheck "$container_name"; do
		echo "Waiting for $container_name to become ready..."
		sleep "$delay";

		# Give the container 30s to become ready
		elapsed=$((elapsed + delay))
		if ((elapsed > timeout)); then
			echo "$container_name heathcheck failed"
			exit 1
		fi
	done

	return 0
}

# To work on a specific test:
# run `export SKIP=1` locally, then comment skip in the test you want to debug

@test "${NAME} container is up and using the \"${IMAGE}\" image" {
	[[ ${SKIP} == 1 ]] && skip

	run _healthcheck_wait
	unset output

	# Using "bash -c" here to expand ${DOCKER} (in case it's more that a single word).
	# Without bats run returns "command not found"
	run bash -c "${DOCKER} ps --filter 'name=${NAME}' --format '{{ .Image }}'"
	[[ "$output" =~ "${IMAGE}" ]]
	unset output
}

@test "Caching for 200 responses" {
	[[ $SKIP == 1 ]] && skip

	# Confirm a cache MISS 1st time
	run curl -sSk -I http://varnish.docksal.site:2580/index.html
	echo "$output" | grep "HTTP/1.1 200 OK"
	echo "$output" | grep "X-Varnish-Cache: MISS"
	unset output

	# Confirm a cache HIT 2nd time
	run curl -sSk -I http://varnish.docksal.site:2580/index.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	unset output
}

@test "Caching for 404 responses" {
	[[ $SKIP == 1 ]] && skip

	# Confirm a cache MISS 1st time
	run curl -sSk -I http://varnish.docksal.site:2580/nonsense.html
	[[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
	[[ "$output" =~ "X-Varnish-Cache: MISS" ]]
	unset output

	# Confirm a cache HIT 2nd time
	run curl -sSk -I http://varnish.docksal.site:2580/nonsense.html
	[[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	unset output
}

@test "PURGE request" {
	[[ $SKIP == 1 ]] && skip

	# Create a new file and warm-up the cache
	echo "TEST OUTPUT" > tests/docroot/index2.html
	curl -sSk -i http://varnish.docksal.site:2580/index2.html
	# Modify the file
	echo "TEST OUTPUT2" >> tests/docroot/index2.html

	# Confirm the cached version is returned
	run curl -sSk -i http://varnish.docksal.site:2580/index2.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	[[ "$output" =~ "TEST OUTPUT" ]]
	[[ ! "$output" =~ "TEST OUTPUT2" ]]
	unset output

	# Confirm new file is returned after PURGE
	curl -X PURGE http://varnish.docksal.site:2580/index2.html
	# Give varnish a bit of time to process the purge
	sleep 1
	run curl -sSk -i http://varnish.docksal.site:2580/index2.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: MISS" ]]
	[[ "$output" =~ "TEST OUTPUT" ]]
	[[ "$output" =~ "TEST OUTPUT2" ]]
	unset output
}

@test "BAN request" {
	[[ $SKIP == 1 ]] && skip

	# Check cache tags header are present in the response from backend
	run curl -sSk -I http://varnish.docksal.site:2581/ban.html
	[[ "$output" =~ "Cache-Tags: ban.test" ]]
	unset output

	# Warm-up cache, check for a HIT and that the cache tags header is stripped from Varnish response
	curl -sSk http://varnish.docksal.site:2580/ban.html &>/dev/null
	run curl -sSk -I http://varnish.docksal.site:2580/ban.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	[[ ! "$output" =~ "Cache-Tags: ban.test" ]]
	unset output

	# Add a BAN
	run curl -sSk -X BAN -I -H "Cache-Tags: ban.test"  http://varnish.docksal.site:2580/ban.html
	[[ "$output" =~ "HTTP/1.1 200 Ban added" ]]
	unset output

	# Confirm ban exists in ban.list
	run make exec -e CMD='varnishadm ban.list'
	[[ "$output" =~ "ban.test" ]]
	unset output

	# Confirm cache was purged
	run curl -sSk -I http://varnish.docksal.site:2580/ban.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: MISS" ]]
	unset output
}

@test "Config templates" {
	[[ $SKIP == 1 ]] && skip

	# Restart with config overrides
	ENV="\
		-e VARNISH_BACKEND_HOST=${NAME}-web \
		-e VARNISH_SECRET=varnish-secret \
		-e VARNISH_CACHE_TAGS_HEADER=Cache-Tags-Custom \
	"\
		make start

	run _healthcheck_wait
	unset output

	### Tests ###
	run make exec -e CMD='cat /etc/varnish/secret | grep "$${VARNISH_SECRET}"'
	[[ "VARNISH_SECRET" && ${status} == 0 ]]
	unset output

	run make exec -e CMD='cat /etc/varnish/default.vcl | grep "req.http.$${VARNISH_CACHE_TAGS_HEADER}"'
	[[ "VARNISH_CACHE_TAGS_HEADER" && ${status} == 0 ]]
	unset output
}
