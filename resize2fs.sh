#!/usr/bin/env bash

#
# Because resize2fs can't detect minimal block size by itself
# We will do this in this simple script
#

set -e

function get_min_block_size_kb()
{
    kb_size=$(df $1 | awk '{print $2}')
    reserved_kb_size=$(( kb_size + (1024 * 1024 * 10) )) # 10 GiB
    echo $reserved_kb_size
}

logs="logs_$(date +%Y%m%d)"
mkdir -p $logs

# e2fck
(for fs in $*; do
    echo "$fs >& $logs/$(basename $fs).e2fsck.log"
done) | xargs -I{} -P10 bash -c "time e2fsck -f {}"


# resize
(for fs in $*; do
    echo "$fs $(get_min_block_size_kb $fs) >& $logs/$(basename $fs).resize2fs.log"
done) | xargs -I{} -P10 bash -c "time resize2fs {}"

