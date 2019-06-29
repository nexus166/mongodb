#!/usr/bin/env bash

export USERNAME="${REG_USR}"
export PASSWORD="${REG_PASS}"

case "${USERNAME}" in
	"") export USERNAME="$(jq -cr '.auths."https://index.docker.io/v1/".auth' ~/.docker/config.json | base64 --decode | cut -d':' -f1)";;
esac

case "${PASSWORD}" in
        "") export PASSWORD="$(jq -cr '.auths."https://index.docker.io/v1/".auth' ~/.docker/config.json | base64 --decode | cut -d':' -f2)";;
esac

export ORGANIZATION="${REG:-${USERNAME}}"
export REPOSITORY="${REG_PATH:-$(basename $(git config --get remote.origin.url) .git)}"


_dockerhub_delete() {
	_IMG_PATH=${1:-"${ORGANIZATION}/${REPOSITORY}"}
	set -x
        curl -fsSLo- -u "${USERNAME}:${PASSWORD}" -X "DELETE" "https://cloud.docker.com/v2/repositories/${_IMG_PATH}/tags/${2}/"
	set +x
}

_dockerhub_get() {
	_IMG_PATH=${1:-"${ORGANIZATION}/${REPOSITORY}"}
	set -x
	curl -fsSLo- -u "${USERNAME}:${PASSWORD}" -X "GET" "https://cloud.docker.com/v2/repositories/${_IMG_PATH}/tags/${2}/"
	set +x
}

_dockerhub_list() {
	_IMG_PATH=${1:-"${ORGANIZATION}/${REPOSITORY}"}
	set -x
        curl -fsSLo- -X "GET" "https://registry.hub.docker.com/v1/repositories/${_IMG_PATH}/tags"
	set +x
}

case "${1}" in
	d|D|del*|DEL*|rm|remove)
        	_dockerhub_delete "${2}" "${3}" | jq '.';
	;;
	g|G|get|GET)
		_dockerhub_get "${2}" "${3:-latest}" | jq '.';
	;;
	l|L|ls|list)
		_dockerhub_list "${2}" | jq -r '.[].name';
	;;
	*)
		echo -e "\\nUsage: $(basename $0) rm|get|ls nexus166/ovpnd latest\\n" && exit 127
	;;
esac
