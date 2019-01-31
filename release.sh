#!/usr/bin/env bash

set -e

# No pushes for PRs
if [[ "${TRAVIS_PULL_REQUEST}" == "false" ]]; then
	# Image tag scheme: <software-version>-<image-stability-tag>[-<flavor>]
	if [[ "${TRAVIS_BRANCH}" == "develop" ]]; then
		export STABILITY_TAG="edge"
	elif [[ "${TRAVIS_BRANCH}" == "master" ]]; then
		export STABILITY_TAG=""
	elif [[ "${TRAVIS_TAG}" != "" ]]; then
		export STABILITY_TAG="${TRAVIS_TAG:1:3}"
	else
		# No pushes for any other branches
		exit 0
	fi

	docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"

	IFS=',' read -ra tags <<< "${TAGS}"

	# Push all applicable tag variations
	for tag in "${tags[@]}"; do
		if [[ "${TRAVIS_BRANCH}" == "develop" ]] && [[ "${tag}" =~ "latest" ]]; then continue; fi
		make release TAG="${tag}"
	done
fi
