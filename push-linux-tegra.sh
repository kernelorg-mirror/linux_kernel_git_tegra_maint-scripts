#!/bin/bash

set -e
set -x

. "${0%/*}/tegra-branches.sh.dot"
. "${0%/*}/lib.sh"

opt_dry_run=no

while test $# -gt 0; do
	case $1 in
		-n | --dry-run)
			opt_dry_run=yes
			shift
			;;

		*)
			echo "usage: $0 [options]"
			echo ""
			echo "options:"
			echo "  -n, --dry-run      pretend to push"
			exit 1
			;;
	esac
done

remote=$(get_remote)
args="--force"

if test "x$opt_dry_run" = "xyes"; then
	args="$args --dry-run"
fi

for b in ${branches} for-next; do
    refspecs="${refspecs} ${b}:${b}"
done

git push $args ${remote} ${refspecs}
