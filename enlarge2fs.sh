#!/usr/bin/env bash

. ${0%/*}/common.sh

logs="logs_$(date +%Y%m%d)"
mkdir -p $logs

set -e
set -x

(for fs in $*; do
    echo "$fs $(get_max_fs_size_in_kb $fs)K >& $logs/$(basename $fs).enlarge2fs.log"
done) | xargs -I{} -P10 bash -c "time resize2fs {}"
