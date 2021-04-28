#!/usr/bin/env bash

set -e

# --------- Helper functions --------- #

# Check whether the current build is for a pull request
is_pr ()
{
    [[ "${EVENT_NAME}" == "pull_request" ]]
}

# -------------------------------------#

# No pushes for PRs
is_pr && exit

# Image tag scheme: <software-version>-<image-stability-tag>[-<flavor>]
if [[ "${SOURCE_BRANCH}" == "develop" ]]; then
    export STABILITY_TAG="edge"
elif [[ "${SOURCE_BRANCH}" == "master" ]]; then
    export STABILITY_TAG=""
elif [[ "${SOURCE_TAG}" != "" ]]; then
    export STABILITY_TAG="${SOURCE_TAG:1:3}"
else
    # No pushes for any other branches
    exit 0
fi

docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"

IFS=',' read -ra tags <<< "${TAGS}"

# Push all applicable tag variations
for tag in "${tags[@]}"; do
    if [[ "${SOURCE_BRANCH}" == "develop" ]] && [[ "${tag}" =~ "latest" ]]; then continue; fi
    make release TAG="${tag}"
done
