#!/usr/bin/env bash

#
# TODO: resize partition before copying
#       this will eliminate "count" option for dd
#
# NOTE: md5sum is 300-400 MB/s so it won't slow down copying
#

port=255
bs=16k

dst=$1
shift

function get_image_size_in_bs()
{
    local bs_size=$(df $1 -B$bs | awk '{print $2}')
    echo $bs_size
}

set -e
set -x

for fs in $*; do
    dd if=$fs bs=$bs iflag=direct count=$(get_image_size_in_bs $fs) | tee >(md5sum >&2) | nc -q1 $dst $port
done

