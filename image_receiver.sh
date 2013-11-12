#!/usr/bin/env bash

#
# Examples:
#   One->One  : ./image_receive /dev/sd?1
#   One->Proxy: ./image_receive dst.com /dev/sd?1
#   One->Proxy: ./image_receive dst.com:255 /dev/sda1
#   One->Proxy: ./image_receive "dst.com:255 dst.com:255" /dev/sda1 /dev/sdb1
#

. ${0%/*}/common.sh

proxy_to_dsts=""
# TODO: more accurate check
if [ ! -e "$1" ]; then
    proxy_to_dsts=($1)
    shift
fi

set -e
set -x

# TODO: do we need to calc md5sum from $fs
function receive_and_proxy()
{
    local port=$1
    local fs=$2
    local proxy_dst_str=$3

    local proxy_dst=${proxy_dst_str/:*}
    local proxy_port=${proxy_dst_str/*:}
    if [ -z "$proxy_port" ] || [ "$proxy_port" = "$proxy_dst" ]; then
        proxy_port=$port
    fi

    if $( df $fs | tail -n+2 | grep -q $fs ); then
        echo "$fs is mounted" >&2
        return
    fi

    cmd="nc -nlp $port | tee >(md5sum >&2) | "
    if [ ! -z "$proxy_dst" ]; then
        cmd+="tee >(nc -q1 $proxy_dst $proxy_port) | "
    fi
    cmd+="dd of=$fs oflag=direct iflag=fullblock bs=$bs"
    bash -c "$cmd"
    e2fsck -f -y $fs
}

port=$start_port
i=0
for fs in $*; do
    receive_and_proxy $port $fs ${proxy_to_dsts[i]} &
    let ++port
    if [ ! -z "${proxy_to_dsts[i+1]}"]; then
        let ++i
    fi
done
