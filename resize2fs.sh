#!/usr/bin/env bash

. ${0%/*}/common.sh

logs="logs_$(date +%Y%m%d)"
mkdir -p $logs

set -e
set -x

# resize
(for fs in $*; do
    min_size_4k=$(resize2fs -P $fs 2>/dev/null | awk '{print $NF}')
    min_size_kb=$(( min_size_4k * 4 ))

    #
    # Because resize2fs buggy with detecting minimal block size by itself
    # We will do it ourselfs, and diff what we get.
    #
    diff=$(( $min_size_kb - $(get_min_fs_size_in_kb $fs) ))
    fs_size=$((get_fs_size_in_kb $fs))
    accuracy=$((fs_size / 50)) # 2%

    if [ $diff -lt 0 ] && [ $((0 - diff)) -gt $accuracy ] ; then
        echo "$fs: resize2fs: malformed min size (less up to $(( 0-diff / 1024 / 1024 ))G)" >&2
        continue
    else
        echo "$fs: resize2fs: optimal size greater up to $(( diff / 1024 / 1024 ))G" >&2
    fi

    echo "$fs ${min_size_kb}K >& $logs/$(basename $fs).resize2fs.log"
done) | xargs -I{} -P10 bash -c "time resize2fs {}"
