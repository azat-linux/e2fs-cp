#!/usr/bin/env bash

. ${0%/*}/common.sh

set -e
set -x

get_uuid_i=1
for fs in $*; do
    fs_type=$(get_fstype $fs)
    uuid=$(get_uuid $fs_type $get_uuid_i)
    case $fs_type in
        ext4) tune2fs $fs -U $uuid;;
        xfs)  xfs_admin -U $uuid $fs;;
    esac
    let ++get_uuid_i
done
