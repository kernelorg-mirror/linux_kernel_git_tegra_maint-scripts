#!/bin/bash

set -e
set -x

. "${0%/*}/tegra-branches.sh.dot"

while test $# -gt 0; do
	case $1 in
		--arm-soc)
			branches="$arm_soc"
			shift
			;;

		*)
			echo "usage: $0 [options]"
			echo ""
			echo "options:"
			echo "  --arm-soc    operate on ARM-SoC branches only"
			exit 1
			;;
	esac
done

for branch in ${branches}; do
	tag=tegra-${branch//\//-}

	if git rev-parse --quiet --verify $tag > /dev/null; then
		echo "tag $tag already exists, skipping"
		continue
	fi

	git tag -s $tag $branch
done
