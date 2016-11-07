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

	git tag -s $tag $branch
done
