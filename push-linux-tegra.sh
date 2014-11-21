#!/bin/bash

set -e
set -x

. "${0%/*}/tegra-branches.sh.dot"
. "${0%/*}/lib.sh"

opt_dry_run=no
opt_branches=yes
opt_tags=no

while test $# -gt 0; do
	case $1 in
		-n | --dry-run)
			opt_dry_run=yes
			shift
			;;

		-t | --tags)
			opt_tags=yes
			shift
			;;

		-T | --tags-only)
			opt_branches=no
			opt_tags=yes
			shift
			;;

		*)
			echo "usage: $0 [options]"
			echo ""
			echo "options:"
			echo "  -n, --dry-run      pretend to push"
			echo "  -t, --tags         push tags"
			echo "  -T, --tags-only    push tags only"
			exit 1
			;;
	esac
done

remote=$(get_remote)
args="--force"

if test "x$opt_dry_run" = "xyes"; then
	args="$args --dry-run"
fi

if test "x$opt_branches" = "xyes"; then
	for b in ${branches} for-next; do
		refspecs="${refspecs} ${b}:${b}"
	done
fi

if test "x$opt_tags" = "xyes"; then
	for b in ${branches}; do
		t=tegra-${b/\//-}
		refspecs="${refspecs} ${t}:${t}"
	done
fi

git push $args ${remote} ${refspecs}
