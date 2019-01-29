#!/usr/bin/env bash

set -e

if [[ "${TRAVIS_PULL_REQUEST}" == "false" ]]; then
	# Image tag scheme: <software-version>-<image-stability-tag>
	# Examples:
	# develop => 4.1-edge, 5.2-edge
	# master => 4.1 / 4, 5.2 / 5 / latest
	# 1.0.0 => 4.1-1.0 / 4-1.0, 5.2-1.0 / 5-1.0
	if [[ "${TRAVIS_BRANCH}" == "develop" ]]; then export STABILITY_TAG="edge"; fi
	if [[ "${TRAVIS_BRANCH}" == "master" ]]; then export STABILITY_TAG=""; fi
	if [[ "${TRAVIS_TAG}" != "" ]]; then export STABILITY_TAG="${TRAVIS_TAG:1:3}"; fi

	docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"

	IFS=',' read -ra tags <<< "${TAGS}"

	# Push all applicable tag variations
	for tag in "${tags[@]}"; do
		make release TAG="${tag}";
	done
fi
