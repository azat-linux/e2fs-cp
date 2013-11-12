#!/usr/bin/env bash

#
# NOTE: md5sum is 300-400 MB/s so it won't slow down copying
#
# Examples:
#   One->One : ./image_sender dst.com /dev/sd?1
#   One->Many: ./image_sender "dst1.com dst2.com" /dev/sd?1
#

. ${0%/*}/common.sh
# TODO: handle mg/gb and other stuff
bs_k=${bs/k/}

reserve=1000

dsts=$1
shift

set -e
set -x

port=$start_port
for fs in $*; do
    fs_size=$(get_fs_size_in_kb $fs)
    fs_size_in_bs=$(( fs_size / bs_k ))

    sender_cmd="dd if=$fs bs=$bs iflag=direct count=$(( fs_size_in_bs + reserve)) | tee >(md5sum >&2)"
    for dst in $(echo $dsts); do
        sender_cmd+=" | tee >(nc -q1 $dst $port)"
    done
    sender_cmd+=" > /dev/null"
    bash -c "$sender_cmd" &

    let ++port
done
