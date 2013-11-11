#!/usr/bin/env bash

#
# TODO: resize partition before copying
#       this will eliminate "count" option for dd
#
# NOTE: md5sum is 300-400 MB/s so it won't slow down copying
#

. ${0%/*}/common.sh

dst=$1
shift

set -e
set -x

port=$start_port
for fs in $*; do
    dd if=$fs bs=$bs iflag=direct count=$(get_image_size_in_bs $fs) | tee >(md5sum >&2) | nc -q1 $dst $port &
    let ++port
done
