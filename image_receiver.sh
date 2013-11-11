#!/usr/bin/env bash

. ${0%/*}/common.sh

set -e
set -x

function receive()
{
    fs=$1

    if $( df $fs | tail -n+2 | grep -q $fs ); then
        echo "$fs is mounted" >&2
        return
    fi

    nc -nlp $port | tee -a >(md5sum >&2) | dd of=$fs oflag=direct iflag=fullblock bs=$bs
    e2fsck -f -y $fs
}

port=$start_port
for fs in $*; do
    receive $fs &
    # TODO: do we need to calc md5sum from $fs
    let ++port
done

