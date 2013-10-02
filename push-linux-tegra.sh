#!/bin/bash

set -e
set -x

. `dirname $0`/tegra-branches.sh.dot

for b in ${branches} for-next; do
    git push --force korg_swarren_linux-tegra ${b}:${b}
done
