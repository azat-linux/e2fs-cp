#!/usr/bin/env bash

#
# TODO: resize partition before copying
#       this will eliminate "count" option for dd
#
# NOTE: md5sum is 300-400 MB/s so it won't slow down copying
#

start_port=255

set -e

port=$start_port
for fs in $*; do
    dd if=$fs bs=16K iflag=direct | tee >(md5sum >&2) | nc -q1 dst $port
    port=$(( port + 1 ))
done

