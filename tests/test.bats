#!/usr/bin/env bats

# Debugging
# TODO: looks like this only outputs the first line instead of all lines.
teardown() {
	echo "Status: $status"
	echo "Output:"
	echo "================================================================"
	for line in "${lines[@]}"; do
		echo $line
	done
	echo "================================================================"
}

setup() {
  ### Setup ###
  cd $(pwd)/../tests && fin start
}

cleanup() {
  ### Cleanup ###
  fin rm -f >/dev/null 2>&1 || true
}

# Global skip
# Uncomment below, then comment skip in the test you want to debug. When done, reverse.
#SKIP=1

@test "Bare server" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	setup

	### Tests ###

  # Confirm 200 Returns a Miss First Time
	run curl -sSk -i http://varnish.tests.docksal
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
  [[ "$output" =~ "X-Varnish-Cache: MISS" ]]
  unset output

  # Confirm 200 2nd Time Returns a HIT
  run curl -sSk -i http://varnish.tests.docksal
  [[ "$output" =~ "HTTP/1.1 200 OK" ]]
  [[ "$output" =~ "X-Varnish-Cache: HIT" ]]
  unset output

  # Confirm 404 Returns a Miss First Time
	run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
  [[ "$output" =~ "X-Varnish-Cache: MISS" ]]
  unset output

  # Confirm 404 2nd Time Returns a HIT
  run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
  [[ "$output" =~ "X-Varnish-Cache: HIT" ]]
  unset output

  # Create nonsense.html file and return HIT for cache.
  echo "TEST OUTPUT" > docroot/nonsense.html
  run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
  [[ "$output" =~ "X-Varnish-Cache: HIT" ]]
  unset output

  # Confirm Purge Works
  run curl -X PURGE -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 200 Purged" ]]
  unset output

  # Confirm new file is returned as cache was cleared for URL
  run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 200 OK" ]]
  [[ "$output" =~ "X-Varnish-Cache: MISS" ]]
  unset output
  
  # Confirm File is in Cache
  run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 200 OK" ]]
  [[ "$output" =~ "X-Varnish-Cache: HIT" ]]
  unset output
  
  # Confirm Cache is still only showing.
  echo "TEST OUTPUT2" >> docroot/nonsense.html
  run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 200 OK" ]]
  [[ "$output" =~ "X-Varnish-Cache: HIT" ]]
  [[ "$output" =~ "TEST OUTPUT" ]]
  [[ ! "$output" =~ "TEST OUTPUT2" ]]
  unset output
  
  # Confirm Purge Works
  run curl -X PURGE -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 200 Purged" ]]
  unset output
  
  # Confirm Purge Works and new output shows
  run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 200 OK" ]]
  [[ "$output" =~ "X-Varnish-Cache: MISS" ]]
  [[ "$output" =~ "TEST OUTPUT" ]]
  [[ "$output" =~ "TEST OUTPUT2" ]]
  unset output

  # Confirm Purge Works and new output shows
  run curl -sSk -i http://varnish.tests.docksal/nonsense.html
  [[ "$output" =~ "HTTP/1.1 200 OK" ]]
  [[ "$output" =~ "X-Varnish-Cache: HIT" ]]
  [[ "$output" =~ "TEST OUTPUT" ]]
  [[ "$output" =~ "TEST OUTPUT2" ]]
  unset output

	### Cleanup ###
  cleanup
}

@test "Configuration overrides" {
	[[ $SKIP == 1 ]] && skip

  ### Setup ###
	setup

	### Tests ###


  ### Cleanup ###
  cleanup
}

@test "Check config templates" {
	[[ $SKIP == 1 ]] && skip

  ### Setup ###
	setup
	echo "VARNISH_IMAGE=\"${IMAGE}\"" > .docksal/docksal-local.env
	fin reset -f

	### Tests ###

	# Load environment variables from docksal.env and confirm then are not empty
	source .docksal/docksal.env
	[[ "${VARNISH_SECRET}" == "changeme" ]]

	# Check VARNISH_SECRET variable is passed
	run CONTAINER_NAME=varnish fin exec 'echo ${VARNISH_SECRET}'
	[[ "${output}" == "changeme" ]]
	unset output
	
  # Check secret file is the same as VARNISH_SECRET
  run CONTAINER_NAME=varnish fin exec 'cat /etc/varnish/secret'
	[[ "${output}" == "changeme" ]]
	unset output

  ### Cleanup ###
  cleanup
	rm -f .docksal/docksal-local.env
}