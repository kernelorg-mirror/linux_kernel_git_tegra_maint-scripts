#!/bin/sh

set -e
#set -x

. "${0%/*}/tegra-branches.sh.dot"
. "${0%/*}/lib.sh"

default_branches="$branches for-next"
branches=

function usage()
{
	echo "usage: $1 [options]"
	echo ""
	echo "options:"
	echo "  -i, --incremental    build all branches incrementally"
	echo "  -j, --jobs JOBS      number of parallel jobs to run"
	echo "  -k, --keep           do not clean up worktree"
	echo "  -n, --dry-run        display what would be done"
	echo "  -o, --output DIR     set build output directory"
	echo "  -w, --worktree DIR   set worktree directory"
}

outputdir=build/tegra
worktree=
dry_run=no
incremental=no
num_jobs=1
keep=no

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

		-k | --keep)
			keep=yes
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

		-w | --worktree)
			prev=worktree
			shift
			;;

		-* | --*)
			usage $0
			exit 1
			;;

		*)
			branches="$branches $1"
			shift
			;;
	esac
done

if test "x$branches" = "x"; then
	branches="$default_branches"
fi

if test "x$worktree" != "x"; then
	oldpwd=`pwd`
	git worktree add --detach "$worktree"
	cd "$worktree"
fi

for branch in ${branches}; do
	if test "x$dry_run" = "xyes"; then
		echo "dry-run: building $branch"
	else
		if test "x$worktree" != "x"; then
			git reset --hard ${branch}
		else
			git checkout ${branch}
		fi
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

if test "x$worktree" != "x" -a "x$keep" = "xno"; then
	cd "$oldpwd"
	git worktree remove "$worktree"
fi
