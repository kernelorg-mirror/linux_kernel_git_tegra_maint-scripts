#!/bin/bash

set -e
set -x

. `dirname $0`/tegra-branches.sh.dot

remote=`git remote -v|grep ra.kernel.org:/pub/scm/linux/kernel/git/tegra/linux|head -n 1|awk '{print $1}'`

for b in ${branches} for-next; do
    git push --force ${remote} ${b}:${b}
done
