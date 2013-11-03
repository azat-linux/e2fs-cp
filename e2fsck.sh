#!/usr/bin/env bash

set -e
set -x

logs="logs_$(date +%Y%m%d)"
mkdir -p $logs

# e2fck
(for fs in $*; do
    echo "$fs >& $logs/$(basename $fs).e2fsck.log"
done) | xargs -I{} -P10 bash -c "time e2fsck -f {}"

