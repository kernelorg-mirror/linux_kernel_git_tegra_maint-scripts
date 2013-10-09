#!/bin/bash

set -e
set -x

. `dirname $0`/tegra-branches.sh.dot

for b in ${branches} for-next; do
    git push --force ra.kernel.org:/pub/scm/linux/kernel/git/tegra/linux.git ${b}:${b}
done
