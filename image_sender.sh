#!/usr/bin/env bash

#
# TODO: resize partition before copying
#       this will eliminate "count" option for dd
#
# NOTE: md5sum is 300-400 MB/s so it won't slow down copying
#

start_port=255
bs=16k
reserve=1000

dst=$1
shift

function get_image_size_in_bs()
{
    local dumpfs=$(dumpe2fs -h $1 | awk -F: '{if ($1 == "Block size") bs=$NF; if ($1 == "Block count") count=$NF;} END {print bs count}')
    local fs_bs_k=$(echo $dumpfs | awk '{print $1/1024}')
    local fs_count=$(echo $dumpfs | awk '{print $2}')

    # TODO: handle mg/gb and other stuff
    local bs_k=${bs/k/}

    echo $(( (fs_count / (bs_k / fs_bs_k)) + reserve ))
}

set -e
set -x

port=$start_port
for fs in $*; do
    dd if=$fs bs=$bs iflag=direct count=$(get_image_size_in_bs $fs) | tee >(md5sum >&2) | nc -q1 $dst $port &
    let ++port
done

