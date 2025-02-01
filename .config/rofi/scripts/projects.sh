#!/usr/bin/env bash

cd

if [ $# -ne 0 ]; then
	coproc (code "$@" >/dev/null 2>&1)
	exit 0
fi

fd --prune '^.git|.jj$' dev -utd -x echo {//} | sort | uniq
