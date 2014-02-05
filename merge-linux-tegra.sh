#!/bin/bash

set -e
set -x

. `dirname $0`/tegra-branches.sh.dot

if [ "$1" != "--no-reset" ]; then
  git checkout for-next
  git reset --hard v3.14-rc1
fi

for b in ${branches}; do
    git merge -m "Merge branch ${b} into for-next" --no-ff ${b}
done
