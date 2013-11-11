#!/usr/bin/env bash

#
# TODO: not sure about e2fsck -y option (is this safe?)
#

. ${0%/*}/common.sh

set -e
set -x

logs="logs_$(date +%Y%m%d)"
mkdir -p $logs

# e2fck
(for fs in $*; do
    echo "$fs >& $logs/$(basename $fs).e2fsck.log"
done) | xargs -I{} -P$parallel_max bash -c "time e2fsck -y -f {}"
