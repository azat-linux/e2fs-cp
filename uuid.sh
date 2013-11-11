#!/usr/bin/env bash

. ${0%/*}/common.sh

set -e
set -x

get_uuid_i=1
for fs in $*; do
    tune2fs $fs -U $(get_uuid $get_uuid_i)
    let ++get_uuid_i
done
