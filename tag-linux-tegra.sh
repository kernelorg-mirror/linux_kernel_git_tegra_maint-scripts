#!/bin/bash

set -e
set -x

. "${0%/*}/tegra-branches.sh.dot"

for branch in ${branches}; do
	tag=tegra-${branch/\//-}

	git tag -s $tag $branch
done
