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
	health_status=$(docker inspect --format='{{json .State.Health.Status}}' "$1" 2>/dev/null)

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

@test "Bare server" {
	[[ $SKIP == 1 ]] && skip
	### Setup ###
	echo "VARNISH_IMAGE=\"${REPO}:${VERSION}\"" >.docksal/docksal-local.env
	fin rm -f >/dev/null 2>&1
	fin start >/dev/null 2>&1
	# getting new container name for healtcheck
	NAME=$(fin project status 2>/dev/null | grep varnish | awk '{print $1}')
	_healthcheck_wait
}

@test "Confirm 200 Returns a Miss First Time" {
	[[ $SKIP == 1 ]] && skip
	# Confirm 200 Returns a Miss First Time
	run curl -sSk -i http://varnish.tests.docksal
	echo "$output" | grep "HTTP/1.1 200 OK"
	echo "$output" | grep "X-Varnish-Cache: MISS"
	unset output
}

@test "Confirm 200 2nd Time Returns a HIT" {
	[[ $SKIP == 1 ]] && skip
	# Confirm 200 2nd Time Returns a HIT
	run curl -sSk -i http://varnish.tests.docksal
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	unset output
}

@test "Confirm 404 Returns a Miss First Time" {
	[[ $SKIP == 1 ]] && skip
	# Confirm 404 Returns a Miss First Time
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
	[[ "$output" =~ "X-Varnish-Cache: MISS" ]]
	unset output
}

@test "Confirm 404 2nd Time Returns a HIT" {
	[[ $SKIP == 1 ]] && skip
	# Confirm 404 2nd Time Returns a HIT
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	unset output
}

@test "Create nonsense.html file and return HIT for cache" {
	[[ $SKIP == 1 ]] && skip
	# Create nonsense.html file and return HIT for cache
	echo "TEST OUTPUT" > nonsense.html
	echo "TEST OUTPUT" > docroot/nonsense.html
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	unset output
}

@test "Purge cache and confirm new file is returned as cache was cleared for URL" {
	[[ $SKIP == 1 ]] && skip
	# Confirm new file is returned as cache was cleared for URL
	run curl -X PURGE -i http://varnish.tests.docksal/nonsense.html
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: MISS" ]]
	unset output
}

@test "Confirm 2nd time File returned from cache" {
	[[ $SKIP == 1 ]] && skip
	# Confirm File is in Cache
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	unset output
}

@test "Modify file content and Confirm file is still returned from cache" {
	[[ $SKIP == 1 ]] && skip
	# Confirm Cache is still only showing
	echo "TEST OUTPUT2" >> docroot/nonsense.html
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	[[ "$output" =~ "TEST OUTPUT" ]]
	[[ ! "$output" =~ "TEST OUTPUT2" ]]
	unset output
}

@test "Confirm Purge Works and output shows new file content" {
	[[ $SKIP == 1 ]] && skip
	# Confirm Purge Works and output shows new file content
	run curl -X PURGE -i http://varnish.tests.docksal/nonsense.html
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: MISS" ]]
	[[ "$output" =~ "TEST OUTPUT" ]]
	[[ "$output" =~ "TEST OUTPUT2" ]]
	unset output
}

@test "Confirm 2nd time new file content returns from cache" {
	[[ $SKIP == 1 ]] && skip
	# Confirm new file content is in cache
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	[[ "$output" =~ "X-Varnish-Cache: HIT" ]]
	[[ "$output" =~ "TEST OUTPUT" ]]
	[[ "$output" =~ "TEST OUTPUT2" ]]
	unset output
}

@test "Adding BAN test" {
	[[ $SKIP == 1 ]] && skip
	# Confirm BAN added
	run curl -s -X BAN -i -H "cache-tag-header-name: add.this.to.ban"  http://varnish.tests.docksal/nonsense.html
	[[ "$output" =~ "HTTP/1.1 200 Ban added" ]]
	unset output
}

@test "Check BAN exists" {
	[[ $SKIP == 1 ]] && skip
	# Confirm BAN tag exists
	run fin exec --in=varnish "varnishadm ban.list"
	[[ "$output" =~ "add.this.to.ban" ]]
	unset output
	fin rm -f >/dev/null 2>&1 || true
	rm -f docroot/nonsense.html || true
}

@test "Check config templates" {
	[[ $SKIP == 1 ]] && skip
	fin rm -f >/dev/null 2>&1
	fin start >/dev/null 2>&1
	# getting new container name for healtcheck
	NAME=$(fin project status 2>/dev/null | grep varnish | awk '{print $1}')
	_healthcheck_wait

	### Tests ###
	# Load environment variables from docksal.env and confirm then are not empty
	source .docksal/docksal.env
	[[ "${VARNISH_SECRET}" == "changeme" ]]

	# Check VARNISH_SECRET variable is passed
	run fin exec --in=varnish 'echo ${VARNISH_SECRET}' 2>/dev/null
	[[ "${output}" =~ "changeme" ]]
	unset output

	# Check secret file is the same as VARNISH_SECRET
	run fin exec --in=varnish 'cat /etc/varnish/secret'
	[[ "${output}" =~ "changeme" ]]
	unset output
	fin rm -f >/dev/null 2>&1 || true
	rm -f .docksal/docksal-local.env
}
