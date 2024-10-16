#!/usr/bin/env bash

cd

if [ $# -ne 0 ]; then
	coproc (zeditor "$@" >/dev/null 2>&1)
	exit 0
fi

fd --prune '^.git$' dev -utd -x echo {//} | sort
