#!/bin/sh

set -e
#set -x

. "${0%/*}/tegra-branches.sh.dot"
. "${0%/*}/lib.sh"

function usage()
{
	echo "usage: $1 [options]"
	echo ""
	echo "options:"
	echo "  -i, --incremental    build all branches incrementally"
}

outputdir=build/tegra
dry_run=no
incremental=no
num_jobs=1

while test $# -gt 0; do
	if test -n "$prev"; then
		eval "$prev=$1"
		shift; prev=
		continue
	fi

	case $1 in
		-i | --incremental)
			incremental=yes
			shift
			;;

		-j | --jobs)
			prev=num_jobs
			shift
			;;

		-n | --dry-run)
			dry_run=yes
			shift
			;;

		-o | --output)
			prev=outputdir
			shift
			;;

		*)
			usage $0
			exit 1
			;;
	esac
done

for branch in ${branches} for-next; do
	if test "x$dry_run" = "xyes"; then
		echo "dry-run: building $branch"
	else
		git checkout ${branch}
	fi

	while read arch config; do
		if test "x$incremental" = "xno"; then
			KBUILD_OUTPUT="${outputdir}/${branch}/${arch}/${config}"
			logdir="${KBUILD_OUTPUT}"

			if test -d "$KBUILD_OUTPUT"; then
				rm -rf "$KBUILD_OUTPUT"
			fi
		else
			KBUILD_OUTPUT="${outputdir}/${arch}/${config}"
			logdir="${KBUILD_OUTPUT}/logs/${branch}"
		fi

		export KBUILD_OUTPUT
		mkdir -p "${logdir}"

		cross_compile_prepare $arch
		echo -n "  ${arch}:${config} in $KBUILD_OUTPUT... "

		exec 3> "${logdir}/build.log"
		make ${config} >&3 2>&1
		make -j ${num_jobs} >&3 2>&1
		exec 3>&-

		cross_compile_cleanup
		echo "done"
	done < "${0%/*}/configs"
done
