#!/usr/bin/env bash

if [ $# -ne 0 ]; then
	zed "$@"
	exit 0
fi

cd
fd --prune '^.git$' dev -utd -x echo {//} | sort
