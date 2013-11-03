#!/usr/bin/env bash

set -e
set -x

function last_mount_point()
{
    dumpe2fs -h $1 2>/dev/null | grep 'Last mounted on' | awk '{print $NF}'
}

function get_uuid()
{
    grep $(last_mount_point $1) /etc/fstab | cut -d' ' -f1 | cut -d= -f2
}

for fs in $*; do
    tune2fs $fs -U $(get_uuid $fs)
done

