#!/bin/sh

set -eu
cd "$(dirname "$0")/sysfiles"

register() {
	path="$(realpath "$1")"

	rsync --archive --mkpath "$path" ".$path"
}

apply() {
	echo Installing
	find . -type f | sed 's/^./  - /'
	sudo rsync --recursive ./ /
}

case "${1:-unset}" in
register)
	shift
	register "$@"
	;;
apply)
	apply
	;;
unset)
	echo "sysfiles.sh register|apply"
	;;
*)
	echo "unknown option $1"
	;;
esac
