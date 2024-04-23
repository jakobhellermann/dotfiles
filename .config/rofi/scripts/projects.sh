#!/usr/bin/env bash

if [ $# -ne 0 ]; then
	coproc (Zed "$@" >/dev/null 2>&1)
	exit 0
fi

cd
fd --prune '^.git$' dev -utd -x echo {//} | sort
