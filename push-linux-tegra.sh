#!/bin/bash

set -e
set -x

. "${0%/*}/tegra-branches.sh.dot"
. "${0%/*}/lib.sh"

remote=$(get_remote)

for b in ${branches} for-next; do
    git push --force ${remote} ${b}:${b}
done
