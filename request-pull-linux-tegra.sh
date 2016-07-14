#!/bin/bash

set -e
set -x

. "${0%/*}/tegra-branches.sh.dot"
. "${0%/*}/lib.sh"

git_tag_get_subject()
{
	local blank=no

	git show $1 | while read line; do
		if test "x$blank" = "xyes"; then
			echo $line
			break
		fi

		if test -z "$line"; then
			blank=yes
		fi
	done
}

repository=git://git.kernel.org/pub/scm/linux/kernel/git/tegra/linux.git
remote=$(get_remote)

to="arm@kernel.org"
cc="Stephen Warren <swarren@wwwdotorg.org>"
cc="$cc, Thierry Reding <thierry.reding@gmail.com>"
cc="$cc, Alexandre Courbot <gnurou@gmail.com>"
cc="$cc, Jon Hunter <jonathanh@nvidia.com>"
cc="$cc, linux-tegra@vger.kernel.org"
cc="$cc, linux-arm-kernel@lists.infradead.org"

index=1
count=0

for branch in ${arm_soc}; do
	count=$[count + 1]
done

for branch in ${arm_soc}; do
	tag=tegra-${branch//\//-}
	release=${branch%%/*}

	if ! test -d "pull-request/$release"; then
		mkdir -p "pull-request/$release"
	fi

	message=$(printf "pull-request/$release/%04u-$tag" $index)
	name=$(git config --get user.name)
	email=$(git config --get user.email)
	date=$(date -R)
	subject=$(git_tag_get_subject $tag)

	if ! git config --get sendemail.from > /dev/null 2>&1; then
		identity=$(git config --get sendemail.identity)
		from=$(git config --get sendemail.$identity.from)
	else
		from=$(git config --get sendemail.from)
	fi

	exec 3> "$message"

	echo "From $email $date" >&3
	echo "From: $from" >&3
	echo "To: $to" >&3
	echo "Cc: $cc" >&3
	printf "Subject: [GIT PULL %01u/%01u] $subject\n" $index $count >&3
	echo "" >&3
	echo "Hi ARM SoC maintainers," >&3
	echo "" >&3
	git request-pull $merge_base $repository $tag >&3

	exec 3>&-

	index=$[index + 1]
done
