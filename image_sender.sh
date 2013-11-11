#!/usr/bin/env bash

#
# TODO: resize partition before copying
#       this will eliminate "count" option for dd
#
# NOTE: md5sum is 300-400 MB/s so it won't slow down copying
#

. ${0%/*}/common.sh
# TODO: handle mg/gb and other stuff
bs_k=${bs/k/}

reserve=1000

dst=$1
shift

set -e
set -x

port=$start_port
for fs in $*; do
    fs_size=$(get_fs_size_in_kb $fs)
    fs_size_in_bs=$(( fs_size / bs_k ))

    dd if=$fs bs=$bs iflag=direct count=$(( fs_size_in_bs + reserve)) | tee >(md5sum >&2) | nc -q1 $dst $port &
    let ++port
done
