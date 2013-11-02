#!/usr/bin/env bash

#
# Because resize2fs can't detect minimal block size by itself
# We will do this in this simple script
#

function get_min_block_size_kb()
{
    kb_size=$(df $1 | awk '{print $2}')
    reserved_kb_size=$(( kb_size + (1024 * 1024 * 10) )) # 10 GiB
    echo $reserved_kb_size
}

# e2fck
(for fs in $*; do
    echo $fs
done) | xargs -I{} -P10 e2fsck -f {}


# resize
(for fs in $*; do
    echo $fs $(get_min_block_size_kb $fs)
done) | xargs -I{} -P10 resize2fs {}

