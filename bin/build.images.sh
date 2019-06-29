#!/usr/bin/env bash

set -ex

echo "$CONTAINER"

_HOME="$(git rev-parse --show-toplevel)"

TARGET_OS_BASE="${1:-debian}"
TARGET_TAGS=${2:-"stretch-slim buster-slim"}
LATEST_TAG="$(echo ${TARGET_TAGS} | tr ' ' '\n' | tail -1)"

for _target_tag in ${TARGET_TAGS}; do
	CONTAINER_TAG="${TARGET_OS_BASE}-${_target_tag}";
	sed "s|_TAG_|$_target_tag|g" "${_HOME}/${TARGET_OS_BASE}.Dockerfile" | \
	docker build \
		--rm \
		--tag "${CONTAINER}:${CONTAINER_TAG}" \
		-;
done
