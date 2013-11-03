#!/usr/bin/env bash

#
# Because resize2fs can't detect minimal block size by itself
# We will do this in this simple script
#

function get_min_block_size_kb()
{
    mount $1
    kb_size=$(df -BK $1 | tail -n1 | awk '{print $3}' | tr -d K)
    umount $1

    reserved_kb_size=$(( kb_size + (1024 * 1024 * 10) )) # 10 GiB
    echo $reserved_kb_size
}

set -e
set -x

logs="logs_$(date +%Y%m%d)"
mkdir -p $logs

# resize
(for fs in $*; do
    min_size_4k=$(resize2fs -P $fs 2>/dev/null | awk '{print $NF}')
    min_size_kb=$(( min_size_4k * 4 ))
    diff=$(( $min_size_kb - $(get_min_block_size_kb $fs) ))

    if [ $diff -lt 0 ]; then
        echo "$fs: resize2fs: malformed min size" >&2
        continue
    else
        echo "$fs: resize2fs: optimal size greater up to $(( $diff / 1024 / 1024 ))G" >&2
    fi

    echo "$fs ${min_size_kb}K >& $logs/$(basename $fs).resize2fs.log"
done) | xargs -I{} -P10 bash -c "time resize2fs {}"

