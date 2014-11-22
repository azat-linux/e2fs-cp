#!/usr/bin/env bash

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

function image_send()
{
    local port=$1
    local fs=$2

    local fs_size=$(get_fs_size_in_kb $fs)
    local fs_size_in_bs=$(( fs_size / bs_k ))

    if ! read_only $fs; then
        echo "$fs is not remounted as read-only" >&2
        echo "Run next command to change this:" >&2
        echo "mount -o remount,ro $fs" >&2
        return
    fi

    local sender_cmd="dd if=$fs bs=$bs iflag=direct count=$(( fs_size_in_bs + reserve )) | tee >(md5sum >&2)"
    for dst in $(echo $dsts); do
        sender_cmd+=" | tee >(nc -q1 $dst $port)"
    done
    sender_cmd+=" > /dev/null"
    bash -c "$sender_cmd"
}

port=$start_port
for fs in $*; do
    image_send $port $fs &
    let ++port
done
