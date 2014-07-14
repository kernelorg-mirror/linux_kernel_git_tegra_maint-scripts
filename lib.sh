#!/bin/bash

get_remote()
{
	path=pub/scm/linux/kernel/git/tegra/linux.git
	var=$1

	git remote -v | while read name url spec; do
		case "$url" in
			*.kernel.org:/$path | *.kernel.org:$path)
				echo "$name"
				break
				;;

			*)
				;;
		esac
	done
}
