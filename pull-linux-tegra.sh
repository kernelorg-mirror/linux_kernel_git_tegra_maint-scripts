#!/bin/bash

set -e
set -x

. "${0%/*}/tegra-branches.sh.dot"
. "${0%/*}/lib.sh"

remote=$(get_remote)

git fetch $remote

for b in ${branches} for-next; do
	if ! git rev-parse ${b} > /dev/null 2>&1; then
		git branch ${b} ${remote}/${b}
	else
		git checkout ${b}
		git reset --hard ${remote}/${b}
	fi
done
